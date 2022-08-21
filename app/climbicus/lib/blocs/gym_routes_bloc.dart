import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/constants.dart';
import 'package:climbicus/models/app/route_user_meta.dart';
import 'package:climbicus/models/points.dart';
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
  final double? quality;
  final String? difficulty;
  const UserRouteVotesData(this.quality, this.difficulty);
}


abstract class GymRoutesState {
  const GymRoutesState();
}

class GymRoutesUninitialized extends GymRoutesState {}

class GymRoutesLoading extends GymRoutesState {}

class GymRoutesLoaded extends GymRoutesState {
  final GymRoutes entries;
  final GymRoutes entriesFiltered;
  const GymRoutesLoaded({required this.entries, required this.entriesFiltered}) ;
}

class GymRoutesError extends GymRoutesState {
  FlutterErrorDetails errorDetails;

  GymRoutesError({required Object exception, StackTrace? stackTrace}):
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
  const FilterSentGymRoutes({required this.enabled, required this.category});
}

class FilterAttemptedGymRoutes extends GymRoutesEvent {
  final bool enabled;
  final String category;
  const FilterAttemptedGymRoutes({required this.enabled, required this.category});
}

class FilterGradesGymRoutes extends GymRoutesEvent {
  final GradeValues gradeValues;
  final String category;
  const FilterGradesGymRoutes({required this.gradeValues, required this.category});
}

class AddNewUserRouteLog extends GymRoutesEvent {
  final int routeId;
  final bool completed;
  final int? numAttempts;
  const AddNewUserRouteLog({
    required this.routeId,
    required this.completed,
    required this.numAttempts,
  });
}

class AddOrUpdateUserRouteVotes extends GymRoutesEvent {
  final int routeId;
  final UserRouteVotesData userRouteVotesData;
  const AddOrUpdateUserRouteVotes({
    required this.routeId,
    required this.userRouteVotesData,
  });
}

class AddNewGymRouteWithUserLog extends GymRoutesEvent {
  final int areaId;
  final String category;
  final String grade;
  final String color;
  final File image;
  final List<SerializableOffset> points;
  final String? name;
  final bool completed;
  final int? numAttempts;
  final List<RouteImage> routeImages;
  final UserRouteVotesData userRouteVotesData;
  const AddNewGymRouteWithUserLog({
    required this.areaId,
    required this.category,
    required this.grade,
    required this.color,
    required this.image,
    required this.points,
    required this.name,
    required this.completed,
    required this.numAttempts,
    required this.routeImages,
    required this.userRouteVotesData,
  });
}

class DeleteUserLog extends GymRoutesEvent {
  final UserRouteLog userRouteLog;

  const DeleteUserLog({required this.userRouteLog});
}

class GymRoutesBloc extends Bloc<GymRoutesEvent, GymRoutesState> {
  final getIt = GetIt.instance;

  final RouteImagesBloc routeImagesBloc;

  late GymRoutes _entries;
  GymRoutes get _entriesFiltered => filterEntries();

  late Map<String, bool> _sentFilterEnabled;
  late Map<String, bool> _attemptedFilterEnabled;
  late Map<String, GradeValues> _gradesFilter;

  GymRoutesBloc({required this.routeImagesBloc}) : super(GymRoutesUninitialized()) {
    _sentFilterEnabled = Map.fromIterable(ROUTE_CATEGORIES,
      key: ((category) => category),
      value: (_) => false,
    );
    _attemptedFilterEnabled = Map.fromIterable(ROUTE_CATEGORIES,
      key: ((category) => category),
      value: (_) => false,
    );
    _gradesFilter = Map.fromIterable(ROUTE_CATEGORIES,
      key: ((category) => category),
      value: (category) => GradeValues(0, (GRADE_SYSTEMS[DEFAULT_GRADE_SYSTEM[category]!]!.length - 1)),
    );
  }

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

        _entries = GymRoutes(newRoutes, newLogbook, newVotes);

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

      _entries.updateRoute(
        jsonmdl.Route.fromJson(results["route"]),
        userRouteLog: UserRouteLog.fromJson(results["user_route_log"]),
      );

      // Fetching images in case this was a new route added.
      routeImagesBloc.add(FetchRouteImages(routeIds: [event.routeId]));

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
        userRouteVotes: UserRouteVotes.fromJson(results["user_route_votes"]),
      );

      // Fetching images in case this was a new route added.
      routeImagesBloc.add(FetchRouteImages(routeIds: [event.routeId]));

      yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);
    } else if (event is AddNewGymRouteWithUserLog) {
      var results = await getIt<ApiRepository>().routeAdd(event.areaId, event.category, event.grade, event.color, event.points, event.name);
      var newRoute = jsonmdl.Route.fromJson(results["route"]);

      _entries.addRoute(newRoute);

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

      routeImagesBloc.add(AddNewRouteImage(
        routeId: newRoute.id,
        image: event.image,
      ));

      // for (var routeImage in event.routeImages) {
      //   routeImagesBloc.add(AddNewRouteImage(
      //     routeId: newRoute.id,
      //     routeImage: routeImage,
      //   ));
      // }
    } else if (event is DeleteUserLog) {
      var results = await getIt<ApiRepository>().deleteUserRouteLog(event.userRouteLog.id);

      _entries.deleteUserRouteLog(event.userRouteLog);
      _entries.updateRoute(
        jsonmdl.Route.fromJson(results["route"]),
      );

      yield GymRoutesLoaded(entries: _entries, entriesFiltered: _entriesFiltered);
    }

    return;
  }

  GymRoutes filterEntries() {
    var entriesFiltered = GymRoutes.from(_entries);

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
