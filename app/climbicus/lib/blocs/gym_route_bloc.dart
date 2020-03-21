import 'dart:async';

import 'package:climbicus/blocs/route_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/user_route_log_bloc.dart';
import 'package:climbicus/json/route.dart' as jsonmdl;
import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/utils/api.dart';

abstract class GymRouteEvent {
  const GymRouteEvent();
}

class FetchGymRoute extends GymRouteEvent {}

class AppendGymRouteWithUserLog extends GymRouteEvent {
  final String grade;
  final String status;
  final RouteImage routeImage;
  const AppendGymRouteWithUserLog({this.grade, this.status, this.routeImage});
}

class UpdateGymRoute extends GymRouteEvent {}


class GymRouteBloc extends RouteBloc<GymRouteEvent, RouteState> {
  final ApiProvider api = ApiProvider();
  final RouteImagesBloc routeImagesBloc;
  final UserRouteLogBloc userRouteLogBloc;

  Map<int, jsonmdl.Route> _entries = {};
  StreamSubscription routeImagesSubscription;

  GymRouteBloc({this.routeImagesBloc, this.userRouteLogBloc}) {
    routeImagesSubscription = routeImagesBloc.listen((state) {
      if (state is RouteImagesLoaded) {
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
        routeImagesBloc.add(FetchRouteImages(routeIds: routeIds));

        yield RouteLoaded(entries: _entries);
      } catch (e, st) {
        yield RouteError(exception: e, stackTrace: st);
      }
    } else if (event is UpdateGymRoute) {
      yield RouteLoadedWithImages(entries: _entries);
    } else if (event is AppendGymRouteWithUserLog) {
      var newRoute = await api.routeAdd(event.grade);
      _entries[newRoute["id"]] = jsonmdl.Route(
        event.grade,
        newRoute["created_at"],
      );

      yield RouteLoadedWithImages(entries: _entries);

      userRouteLogBloc.add(AppendUserRouteLog(
        routeId: newRoute["id"],
        grade: event.grade,
        status: event.status,
      ));

      routeImagesBloc.add(AppendRouteImage(
        routeId: newRoute["id"],
        routeImage: event.routeImage,
      ));
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
