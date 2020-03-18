import 'dart:async';

import 'package:climbicus/blocs/route_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/json/route.dart' as jsonmdl;
import 'package:climbicus/utils/api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

abstract class GymRouteEvent {
  const GymRouteEvent();
}

class FetchGymRoute extends GymRouteEvent {}

class AppendGymRoute extends GymRouteEvent {
  final String grade;
  const AppendGymRoute({this.grade});
}

class UpdateGymRoute extends GymRouteEvent {}


class GymRouteBloc extends RouteBloc<GymRouteEvent, RouteState> {
  static const TRIGGER = "gym_route";

  final ApiProvider api = ApiProvider();
  final RouteImagesBloc routeImagesBloc;

  Map<int, jsonmdl.Route> _entries = {};
  StreamSubscription routeImagesSubscription;

  GymRouteBloc({@required this.routeImagesBloc}) {
    routeImagesSubscription = routeImagesBloc.listen((state) {
      if (state is RouteImagesLoaded && state.trigger == TRIGGER) {
        add(UpdateGymRoute());
      }
    });
  }

  @override
  RouteState get initialState => RouteUninitialized();

  @override
  Stream<RouteState> mapEventToState(GymRouteEvent event) async* {
    if (event is FetchGymRoute) {
      yield RouteLoading();

      try {
        Map<String, dynamic> result = (await api.fetchRoutes())["routes"];
        _entries = result.map((id, model) =>
            MapEntry(int.parse(id), jsonmdl.Route.fromJson(model)));

        var routeIds = _entries.keys.toList();
        routeImagesBloc.add(FetchRouteImages(routeIds: routeIds, trigger: TRIGGER));

        yield RouteLoaded(entries: _entries);
      } catch (e, st) {
        yield RouteError(exception: e, stackTrace: st);
      }
    } else if (event is UpdateGymRoute) {
      yield RouteLoadedWithImages(entries: _entries);
    } else if (event is AppendGymRoute) {
      var results = await api.routeAdd(event.grade);

      var newEntry = jsonmdl.Route(
        event.grade,
        results["created_at"],
      );
      _entries[results["id"]] = newEntry;

      yield RouteLoadedWithImages(entries: _entries);
    }

    return;
  }

  @override
  void fetch() => add(FetchGymRoute());

  @override
  List<String> displayAttrs(entry) {
    return [entry.grade, entry.createdAt];
  }

  @override
  int routeId(entryId, entry) => entryId;

  @override
  Future<void> close() {
    routeImagesSubscription.cancel();
    return super.close();
  }
}
