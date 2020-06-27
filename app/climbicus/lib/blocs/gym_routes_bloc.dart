import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/constants.dart';
import 'package:climbicus/models/route.dart' as jsonmdl;
import 'package:climbicus/models/route_image.dart';
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:climbicus/utils/route_grades.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class RouteWithLogs {
  jsonmdl.Route route;
  Map<int, UserRouteLog> userRouteLogs;

  RouteWithLogs(this.route, this.userRouteLogs);

  UserRouteLog mostRecentLog() {
    if (userRouteLogs.isEmpty) {
      return null;
    }

    var sortedKeys = userRouteLogs.keys.toList(growable: false)
      ..sort((k1, k2) => userRouteLogs[k2].createdAt.compareTo(userRouteLogs[k1].createdAt));

    return userRouteLogs[sortedKeys.first];
  }

  bool isSent() {
    for (var e in userRouteLogs.entries) {
      if (e.value.completed) {
        return true;
      }
    }

    return false;
  }
}

class RoutesWithLogs {
  Map<int, RouteWithLogs> _data;

  RoutesWithLogs(
      Map<int, jsonmdl.Route> newRoutes,
      Map<int, UserRouteLog> newLogbook) {
    
    _data = newRoutes.map((routeId, route) => MapEntry(routeId, RouteWithLogs(route, {})));
    newLogbook.forEach((_, userRouteLog) {
      addUserRouteLog(userRouteLog);
    });
  }

  RoutesWithLogs.fromRoutesWithLogs(RoutesWithLogs routesWithLogs) {
    _data = routesWithLogs._data;
  }

  bool get isEmpty => _data.isEmpty;

  List<int> routeIds() => _data.keys.toList();

  void addRoute(jsonmdl.Route route) {
    _data[route.id] = RouteWithLogs(route, {});
  }

  void addUserRouteLog(UserRouteLog userRouteLog) {
    _data[userRouteLog.routeId].userRouteLogs[userRouteLog.id] = userRouteLog;
  }

  Map<int, RouteWithLogs> allRoutes() => _data;

  void filterSent(String category) {
    _data = Map.from(_data)..removeWhere((routeId, routeWithLogs) =>
      (routeWithLogs.route.category == category) && (routeWithLogs.isSent()));
  }

  void filterAttempted(String category) {
    _data = Map.from(_data)..removeWhere((routeId, routeWithLogs) =>
      (routeWithLogs.route.category == category) && (!routeWithLogs.isSent()));
  }

  void filterGrades(String category, GradeValues gradeValues) {
    _data = Map.from(_data)..removeWhere((routeId, routeWithLogs) =>
      (routeWithLogs.route.category == category) && (
      (routeWithLogs.route.upperGradeIndex() < gradeValues.start) ||
      (routeWithLogs.route.lowerGradeIndex() > gradeValues.end))
    );
  }
}


abstract class GymRoutesState {
  const GymRoutesState();
}

class GymRoutesUninitialized extends GymRoutesState {}

class GymRoutesLoading extends GymRoutesState {}

class GymRoutesLoaded extends GymRoutesState {
  final RoutesWithLogs entries;
  final RoutesWithLogs entriesFiltered;
  const GymRoutesLoaded({@required this.entries, @required this.entriesFiltered}) ;
}

class GymRoutesError extends GymRoutesState {
  FlutterErrorDetails errorDetails;

  GymRoutesError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.dumpErrorToConsole(errorDetails);
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

class AddNewGymRouteWithUserLog extends GymRoutesEvent {
  final String category;
  final String grade;
  final bool completed;
  final int numAttempts;
  final List<RouteImage> routeImages;
  const AddNewGymRouteWithUserLog({
    @required this.category,
    @required this.grade,
    @required this.completed,
    @required this.numAttempts,
    @required this.routeImages,
  });
}

class GymRoutesBloc extends Bloc<GymRoutesEvent, GymRoutesState> {
  final getIt = GetIt.instance;

  final RouteImagesBloc routeImagesBloc;

  RoutesWithLogs _entries;
  RoutesWithLogs get _entriesFiltered => filterEntries();

  Map<String, bool> _sentFilterEnabled;
  Map<String, bool> _attemptedFilterEnabled;
  Map<String, GradeValues> _gradesFilter;

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

        var newLogbook = (await dataLogbook).map((userRouteLogId, model) =>
            MapEntry(int.parse(userRouteLogId),
                UserRouteLog.fromJson(model)));
        Map<String, dynamic> resultsRoutes = (await dataRoutes)["routes"];
        var newRoutes = resultsRoutes.map((routeId, model) =>
            MapEntry(int.parse(routeId), jsonmdl.Route.fromJson(model)));

        _entries = RoutesWithLogs(newRoutes, newLogbook);

        yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);

        routeImagesBloc.add(FetchRouteImages(routeIds: _entries.routeIds()));
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
    } else if (event is AddNewGymRouteWithUserLog) {
      var results = await getIt<ApiRepository>().routeAdd(event.category, event.grade);
      var newRoute = jsonmdl.Route.fromJson(results["route"]);
      _entries.addRoute(newRoute);

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
    }

    return;
  }

  RoutesWithLogs filterEntries() {
    var entriesFiltered = RoutesWithLogs.fromRoutesWithLogs(_entries);

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
