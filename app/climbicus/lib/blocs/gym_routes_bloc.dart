import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/json/route.dart' as jsonmdl;
import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/json/user_route_log.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

class RouteWithLogs {
  jsonmdl.Route route;
  Map<int, UserRouteLog> userRouteLogs;

  RouteWithLogs(this.route, this.userRouteLogs);
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

  List<int> routeIds() => _data.keys.toList();

  void addRoute(jsonmdl.Route route) {
    _data[route.id] = RouteWithLogs(route, {});
  }

  void addUserRouteLog(UserRouteLog userRouteLog) {
    _data[userRouteLog.routeId].userRouteLogs[userRouteLog.id] = userRouteLog;
  }

  Map<int, RouteWithLogs> allRoutes() => _data;
}


abstract class GymRoutesState {
  const GymRoutesState();
}

class GymRoutesUninitialized extends GymRoutesState {}

class GymRoutesLoading extends GymRoutesState {}

class GymRoutesLoaded extends GymRoutesState {
  final RoutesWithLogs entries;
  const GymRoutesLoaded({@required this.entries});
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

class UpdateLoadedGymRoutes extends GymRoutesEvent {}

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
  final RouteImage routeImage;
  const AddNewGymRouteWithUserLog({
    @required this.category,
    @required this.grade,
    @required this.completed,
    @required this.numAttempts,
    @required this.routeImage,
  });
}

class GymRoutesBloc extends Bloc<GymRoutesEvent, GymRoutesState> {
  final ApiProvider api = ApiProvider();

  final RouteImagesBloc routeImagesBloc;

  StreamSubscription _routeImagesSubscription;
  RoutesWithLogs _entries;

  GymRoutesBloc({@required this.routeImagesBloc}) {
    _routeImagesSubscription = routeImagesBloc.listen((state) {
      if (state is RouteImagesLoaded) {
        add(UpdateLoadedGymRoutes());
      }
    });
  }

  @override
  GymRoutesState get initialState => GymRoutesUninitialized();

  @override
  Stream<GymRoutesState> mapEventToState(GymRoutesEvent event) async* {
    if (event is FetchGymRoutes) {
      yield GymRoutesLoading();

      try {
        var dataLogbook = api.fetchLogbook();
        var dataRoutes = api.fetchRoutes();

        var newLogbook = (await dataLogbook).map((userRouteLogId, model) =>
            MapEntry(int.parse(userRouteLogId),
                UserRouteLog.fromJson(model)));
        Map<String, dynamic> resultsRoutes = (await dataRoutes)["routes"];
        var newRoutes = resultsRoutes.map((routeId, model) =>
            MapEntry(int.parse(routeId), jsonmdl.Route.fromJson(model)));

        _entries = RoutesWithLogs(newRoutes, newLogbook);

        yield GymRoutesLoaded(entries: _entries);

        routeImagesBloc.add(FetchRouteImages(routeIds: _entries.routeIds()));
      } catch (e, st) {
        yield GymRoutesError(exception: e, stackTrace: st);
      }
    } else if (event is UpdateLoadedGymRoutes) {
      yield GymRoutesLoaded(entries: _entries);
    } else if (event is AddNewUserRouteLog) {
      var results = await api.logbookAdd(event.routeId, event.completed, event.numAttempts);
      var newUserRouteLog = UserRouteLog.fromJson(results["user_route_log"]);

      _entries.addUserRouteLog(newUserRouteLog);

      yield GymRoutesLoaded(entries: _entries);
    } else if (event is AddNewGymRouteWithUserLog) {
      var results = await api.routeAdd(event.category, event.grade);
      var newRoute = jsonmdl.Route.fromJson(results["route"]);
      _entries.addRoute(newRoute);

      this.add(AddNewUserRouteLog(
        routeId: newRoute.id,
        completed: event.completed,
        numAttempts: event.numAttempts,
      ));

      yield GymRoutesLoaded(entries: _entries);

      routeImagesBloc.add(AddNewRouteImage(
        routeId: newRoute.id,
        routeImage: event.routeImage,
      ));
    }

    return;
  }

  @override
  Future<void> close() {
    _routeImagesSubscription.cancel();
    return super.close();
  }
}
