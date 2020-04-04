import 'dart:async';

import 'package:climbicus/blocs/route_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/user_route_log_bloc.dart';
import 'package:climbicus/json/route.dart' as jsonmdl;
import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/time.dart';

abstract class GymRouteEvent {
  const GymRouteEvent();
}

class FetchGymRoutes extends GymRouteEvent {
  final int routeId;
  const FetchGymRoutes({this.routeId});
}

class AddNewGymRouteWithUserLog extends GymRouteEvent {
  final String grade;
  final String status;
  final RouteImage routeImage;
  const AddNewGymRouteWithUserLog({this.grade, this.status, this.routeImage});
}

class UpdateGymRoute extends GymRouteEvent {}


class GymRouteBloc extends RouteBloc<GymRouteEvent, RouteState> {
  static const String TRIGGER = "GymRouteBloc";

  final ApiProvider api = ApiProvider();
  final RouteImagesBloc routeImagesBloc;
  final UserRouteLogBloc userRouteLogBloc;

  Map<int, jsonmdl.Route> _entries = {};
  StreamSubscription _routeImagesSubscription;

  GymRouteBloc({this.routeImagesBloc, this.userRouteLogBloc}) {
    _routeImagesSubscription = routeImagesBloc.listen((state) {
      if (state is RouteImagesLoaded && state.trigger == TRIGGER) {
        add(UpdateGymRoute());
      }
    });
  }

  @override
  RouteState get initialState => RouteUninitialized();

  @override
  Stream<RouteState> mapEventToState(GymRouteEvent event) async* {
    if (event is FetchGymRoutes) {
      yield RouteLoading();

      try {
        var data;
        if (event.routeId != null) {
          if (_entries.containsKey(event.routeId)) {
            yield RouteLoadedWithImages(entries: _entries);
            return;
          }
          data = api.fetchOneRoute(event.routeId);
        } else {
          data = api.fetchRoutes();
        }

        Map<String, dynamic> routes = (await data)["routes"];
        var newEntries = routes.map((routeId, model) =>
            MapEntry(int.parse(routeId), jsonmdl.Route.fromJson(model)));
        _entries.addAll(newEntries);

        var routeIds = _entries.keys.toList();
        routeImagesBloc.add(
            FetchRouteImages(routeIds: routeIds, trigger: TRIGGER));

        yield RouteLoaded(entries: _entries);
      } catch (e, st) {
        yield RouteError(exception: e, stackTrace: st);
      }
    } else if (event is UpdateGymRoute) {
      yield RouteLoadedWithImages(entries: _entries);
    } else if (event is AddNewGymRouteWithUserLog) {
      var newRoute = await api.routeAdd(event.grade);
      // TODO: use fromJson
      _entries[newRoute["id"]] = jsonmdl.Route(
        event.grade,
        DateTime.parse(newRoute["created_at"]),
        api.userId,
      );

      yield RouteLoadedWithImages(entries: _entries);

      userRouteLogBloc.add(AddNewUserRouteLog(
        routeId: newRoute["id"],
        grade: event.grade,
        status: event.status,
      ));

      routeImagesBloc.add(AddNewRouteImage(
        routeId: newRoute["id"],
        routeImage: event.routeImage,
        trigger: TRIGGER,
      ));
    }

    return;
  }

  @override
  void fetch() => add(FetchGymRoutes());

  @override
  String headerTitle(entry) {
    return entry.grade;
  }

  @override
  String bodyTitle(entry) {
    return null;
  }

  @override
  String bodySubtitle(entry) {
    return "added by 'user ${entry.userId.toString()}' (${dateToString(entry.createdAt)})";
  }

  @override
  int routeId(entryId, entry) => entryId;

  @override
  Future<void> close() {
    _routeImagesSubscription.cancel();
    return super.close();
  }
}
