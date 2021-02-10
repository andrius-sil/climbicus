import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/constants.dart';
import 'package:climbicus/models/route.dart' as jsonmdl;
import 'package:climbicus/models/route_image.dart';
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/models/user_route_votes.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:climbicus/utils/route_grades.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';


class UserRouteVotesData {
  final double quality;
  final String difficulty;
  const UserRouteVotesData(this.quality, this.difficulty);
}

class RouteWithUserMeta {
  jsonmdl.Route route;
  Map<int, UserRouteLog> userRouteLogs;
  UserRouteVotes userRouteVotes;

  RouteWithUserMeta(this.route, this.userRouteLogs, this.userRouteVotes);

  UserRouteLog mostRecentLog() {
    if (userRouteLogs.isEmpty) {
      return null;
    }

    var sortedKeys = userRouteLogs.keys.toList(growable: false)
      ..sort((k1, k2) => userRouteLogs[k2].createdAt.compareTo(userRouteLogs[k1].createdAt));

    return userRouteLogs[sortedKeys.first];
  }

  DateTime mostRecentCreatedAt() {
    var log = mostRecentLog();
    if (log != null) {
      return log.createdAt;
    }

    return route.createdAt;
  }

  bool isSent() {
    for (var e in userRouteLogs.entries) {
      if (e.value.completed) {
        return true;
      }
    }

    return false;
  }

  bool isAttempted() => userRouteLogs.isNotEmpty;

  int numAttempts() => userRouteLogs.length;

  double qualityVote() {
    if (userRouteVotes == null) {
      return null;
    }

    return userRouteVotes.quality;
  }

  String difficultyVote() {
    if (userRouteVotes == null) {
      return null;
    }

    return userRouteVotes.difficulty;
  }
}

class RoutesWithUserMeta {
  Map<String, Map<int, RouteWithUserMeta>> _data;
  Map<int, jsonmdl.Route> _routes;

  RoutesWithUserMeta(
      Map<int, jsonmdl.Route> newRoutes,
      Map<int, UserRouteLog> newLogbook,
      Map<int, UserRouteVotes> newVotes,
  ) {

    _routes = newRoutes;
    _data = Map.fromIterable(ROUTE_CATEGORIES,
      key: (category) => category,
      value: (_) => {},
    );

    newRoutes.forEach((routeId, route) {
      _data[route.category][routeId] = RouteWithUserMeta(route, {}, null);
    });

    newLogbook.forEach((_, userRouteLog) {
      addUserRouteLog(userRouteLog);
    });

    newVotes.forEach((_, userRouteVotes) {
      addUserRouteVotes(userRouteVotes);
    });
  }

  RouteWithUserMeta getRouteWithUserMeta(int routeId) {
    String category = _routes[routeId].category;
    return _data[category][routeId];
  }

  RoutesWithUserMeta.fromRoutesWithUserMeta(RoutesWithUserMeta routesWithUserMeta) {
    _data = Map.fromIterable(ROUTE_CATEGORIES,
      key: (category) => category,
      value: (category) => routesWithUserMeta._data[category],
    );
    _routes = routesWithUserMeta._routes;
  }

  bool isEmpty(String category) => _data[category].isEmpty;

  List<int> routeIdsAll() => _routes.keys.toList();
  List<int> routeIds(String category) => _data[category].keys.toList();

  void addRoute(jsonmdl.Route route, UserRouteVotes userRouteVotes) {
    _routes[route.id] = route;
    _data[route.category][route.id] = RouteWithUserMeta(route, {}, userRouteVotes);
  }

  void updateRoute(jsonmdl.Route route, UserRouteVotes userRouteVotes) {
    _routes[route.id] = route;
    _data[route.category][route.id].route = route;
    _data[route.category][route.id].userRouteVotes = userRouteVotes;
  }

  void addUserRouteLog(UserRouteLog userRouteLog) {
    String category = _routes[userRouteLog.routeId].category;
    _data[category][userRouteLog.routeId].userRouteLogs[userRouteLog.id] = userRouteLog;
  }

  void deleteUserRouteLog(UserRouteLog userRouteLog) {
    String category = _routes[userRouteLog.routeId].category;
    _data[category][userRouteLog.routeId].userRouteLogs.remove(userRouteLog.id);
  }

  void addUserRouteVotes(UserRouteVotes userRouteVotes) {
    String category = _routes[userRouteVotes.routeId].category;
    _data[category][userRouteVotes.routeId].userRouteVotes = userRouteVotes;
  }

  UserRouteVotes getUserRouteVotes(int routeId) {
    String category = _routes[routeId].category;
    return _data[category][routeId].userRouteVotes;
  }

  Map<int, RouteWithUserMeta> allRoutes(String category) => _data[category];

  void filterSent(String category) {
    _data[category] = Map.from(_data[category])..removeWhere((routeId, routeWithUserMeta) =>
      (routeWithUserMeta.isSent()));
  }

  void filterAttempted(String category) {
    _data[category] = Map.from(_data[category])..removeWhere((routeId, routeWithUserMeta) =>
      (routeWithUserMeta.isAttempted()));
  }

  void filterGrades(String category, GradeValues gradeValues) {
    _data[category] = Map.from(_data[category])..removeWhere((routeId, routeWithUserMeta) =>
      (routeWithUserMeta.route.category == category) && (
      (routeWithUserMeta.route.upperGradeIndex() < gradeValues.start) ||
      (routeWithUserMeta.route.lowerGradeIndex() > gradeValues.end))
    );
  }
}


abstract class GymRoutesState {
  const GymRoutesState();
}

class GymRoutesUninitialized extends GymRoutesState {}

class GymRoutesLoading extends GymRoutesState {}

class GymRoutesLoaded extends GymRoutesState {
  final RoutesWithUserMeta entries;
  final RoutesWithUserMeta entriesFiltered;
  const GymRoutesLoaded({@required this.entries, @required this.entriesFiltered}) ;
}

class GymRoutesError extends GymRoutesState {
  FlutterErrorDetails errorDetails;

  GymRoutesError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.reportError(errorDetails);
  }
}

abstract class GymRoutesEvent {
  const GymRoutesEvent();
}

class FetchGymRoutes extends GymRoutesEvent {}

class FilterSentGymRoutes extends GymRoutesEvent {
  final bool enabled;
  final String category;
  const FilterSentGymRoutes({@required this.enabled, @required this.category});
}

class FilterAttemptedGymRoutes extends GymRoutesEvent {
  final bool enabled;
  final String category;
  const FilterAttemptedGymRoutes({@required this.enabled, @required this.category});
}

class FilterGradesGymRoutes extends GymRoutesEvent {
  final GradeValues gradeValues;
  final String category;
  const FilterGradesGymRoutes({@required this.gradeValues, @required this.category});
}

class AddNewUserRouteLog extends GymRoutesEvent {
  final int routeId;
  final bool completed;
  final int numAttempts;
  const AddNewUserRouteLog({
    @required this.routeId,
    @required this.completed,
    @required this.numAttempts,
  });
}

class AddOrUpdateUserRouteVotes extends GymRoutesEvent {
  final int routeId;
  final UserRouteVotesData userRouteVotesData;
  const AddOrUpdateUserRouteVotes({
    @required this.routeId,
    @required this.userRouteVotesData,
  });
}

class AddNewGymRouteWithUserLog extends GymRoutesEvent {
  final String category;
  final String grade;
  final String name;
  final bool completed;
  final int numAttempts;
  final List<RouteImage> routeImages;
  final UserRouteVotesData userRouteVotesData;
  const AddNewGymRouteWithUserLog({
    @required this.category,
    @required this.grade,
    @required this.name,
    @required this.completed,
    @required this.numAttempts,
    @required this.routeImages,
    @required this.userRouteVotesData,
  });
}

class DeleteUserLog extends GymRoutesEvent {
  final UserRouteLog userRouteLog;

  const DeleteUserLog({@required this.userRouteLog});
}

class GymRoutesBloc extends Bloc<GymRoutesEvent, GymRoutesState> {
  final getIt = GetIt.instance;

  final RouteImagesBloc routeImagesBloc;

  RoutesWithUserMeta _entries;
  RoutesWithUserMeta get _entriesFiltered => filterEntries();

  Map<String, bool> _sentFilterEnabled;
  Map<String, bool> _attemptedFilterEnabled;
  Map<String, GradeValues> _gradesFilter;
  
  RouteWithUserMeta getGymRoute(int routeId) {
    return _entries.getRouteWithUserMeta(routeId);
  }

  GymRoutesBloc({@required this.routeImagesBloc}) {
    _sentFilterEnabled = Map.fromIterable(ROUTE_CATEGORIES,
      key: (category) => category,
      value: (_) => false,
    );
    _attemptedFilterEnabled = Map.fromIterable(ROUTE_CATEGORIES,
      key: (category) => category,
      value: (_) => false,
    );
    _gradesFilter = Map.fromIterable(ROUTE_CATEGORIES,
      key: (category) => category,
      value: (category) => GradeValues(0, (GRADE_SYSTEMS[DEFAULT_GRADE_SYSTEM[category]].length - 1)),
    );
  }

  @override
  GymRoutesState get initialState => GymRoutesUninitialized();

  @override
  Stream<GymRoutesState> mapEventToState(GymRoutesEvent event) async* {
    if (event is FetchGymRoutes) {
      yield GymRoutesLoading();

      try {
        var dataLogbook = getIt<ApiRepository>().fetchLogbook();
        var dataRoutes = getIt<ApiRepository>().fetchRoutes();
        var dataVotes = getIt<ApiRepository>().fetchVotes();

        var newLogbook = (await dataLogbook).map((userRouteLogId, model) =>
            MapEntry(int.parse(userRouteLogId), UserRouteLog.fromJson(model)));
        Map<String, dynamic> resultsRoutes = (await dataRoutes)["routes"];
        var newRoutes = resultsRoutes.map((routeId, model) =>
            MapEntry(int.parse(routeId), jsonmdl.Route.fromJson(model)));
        var newVotes = (await dataVotes).map((userRouteVotesId, model) =>
            MapEntry(int.parse(userRouteVotesId), UserRouteVotes.fromJson(model)));

        _entries = RoutesWithUserMeta(newRoutes, newLogbook, newVotes);

        yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);

        routeImagesBloc.add(FetchRouteImages(routeIds: _entries.routeIdsAll()));
      } catch (e, st) {
        yield GymRoutesError(exception: e, stackTrace: st);
      }
    } else if (event is FilterSentGymRoutes) {
      _sentFilterEnabled[event.category] = event.enabled;

      yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);
    } else if (event is FilterAttemptedGymRoutes) {
      _attemptedFilterEnabled[event.category] = event.enabled;

      yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);
    } else if (event is FilterGradesGymRoutes) {
      _gradesFilter[event.category] = event.gradeValues;

      yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);
    } else if (event is AddNewUserRouteLog) {
      var results = await getIt<ApiRepository>().logbookAdd(event.routeId, event.completed, event.numAttempts);
      var newUserRouteLog = UserRouteLog.fromJson(results["user_route_log"]);

      _entries.addUserRouteLog(newUserRouteLog);

      yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);
    } else if (event is AddOrUpdateUserRouteVotes) {
      var results;
      var userRouteVotes = _entries.getUserRouteVotes(event.routeId);
      if (userRouteVotes != null) {
        results = await getIt<ApiRepository>().userRouteVotesUpdate(
          userRouteVotes.id,
          event.userRouteVotesData.quality,
          event.userRouteVotesData.difficulty,
        );
      } else {
        results = await getIt<ApiRepository>().userRouteVotesAdd(
          event.routeId,
          event.userRouteVotesData.quality,
          event.userRouteVotesData.difficulty,
        );
      }

      _entries.updateRoute(
        jsonmdl.Route.fromJson(results["route"]),
        UserRouteVotes.fromJson(results["user_route_votes"]),
      );

      yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);
    } else if (event is AddNewGymRouteWithUserLog) {
      var results = await getIt<ApiRepository>().routeAdd(event.category, event.grade, event.name);
      var newRoute = jsonmdl.Route.fromJson(results["route"]);

      _entries.addRoute(newRoute, null);

      this.add(AddOrUpdateUserRouteVotes(
        routeId: newRoute.id,
        userRouteVotesData: event.userRouteVotesData,
      ));

      this.add(AddNewUserRouteLog(
        routeId: newRoute.id,
        completed: event.completed,
        numAttempts: event.numAttempts,
      ));

      yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);

      for (var routeImage in event.routeImages) {
        routeImagesBloc.add(AddNewRouteImage(
          routeId: newRoute.id,
          routeImage: routeImage,
        ));
      }
    } else if (event is DeleteUserLog) {
      _entries.deleteUserRouteLog(event.userRouteLog);

      yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);
    }

    return;
  }

  RoutesWithUserMeta filterEntries() {
    var entriesFiltered = RoutesWithUserMeta.fromRoutesWithUserMeta(_entries);

    _sentFilterEnabled.forEach((category, enabled) {
      if (enabled) {
        entriesFiltered.filterSent(category);
      }
    });

    _attemptedFilterEnabled.forEach((category, enabled) {
      if (enabled) {
        entriesFiltered.filterAttempted(category);
      }
    });

    _gradesFilter.forEach((category, gradeValues) {
      entriesFiltered.filterGrades(category, gradeValues);
    });

    return entriesFiltered;
  }
}
