import 'dart:async';

import 'package:climbicus/blocs/route_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/json/user_route_log_entry.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

abstract class UserRouteLogEvent {
  const UserRouteLogEvent();
}

class FetchUserRouteLog extends UserRouteLogEvent {}

class AppendUserRouteLog extends UserRouteLogEvent {
  final int routeId;
  final String grade;
  final String status;
  const AppendUserRouteLog({this.routeId, this.grade, this.status});
}

class UpdateUserRouteLog extends UserRouteLogEvent {}


class UserRouteLogBloc extends RouteBloc<UserRouteLogEvent, RouteState> {
  static const TRIGGER = "user_route_log";

  final ApiProvider api = ApiProvider();
  final RouteImagesBloc routeImagesBloc;

  Map<int, UserRouteLogEntry> _entries = {};
  StreamSubscription routeImagesSubscription;

  UserRouteLogBloc({@required this.routeImagesBloc}) {
    routeImagesSubscription = routeImagesBloc.listen((state) {
      if (state is RouteImagesLoaded && state.trigger == TRIGGER) {
        add(UpdateUserRouteLog());
      }
    });
  }

  @override
  RouteState get initialState => RouteUninitialized();

  @override
  Stream<RouteState> mapEventToState(UserRouteLogEvent event) async* {
    if (event is FetchUserRouteLog) {
      yield RouteLoading();

      try {
        _entries = (await api.fetchLogbook()).map((id, model) =>
            MapEntry(int.parse(id), UserRouteLogEntry.fromJson(model)));

        var routeIds = _entries.values.map((entry) => entry.routeId).toList();
        routeImagesBloc.add(FetchRouteImages(routeIds: routeIds, trigger: TRIGGER));

        yield RouteLoaded(entries: _entries);
      } catch (e, st) {
        yield RouteError(exception: e, stackTrace: st);
      }
    } else if (event is UpdateUserRouteLog) {
      yield RouteLoadedWithImages(entries: _entries);
    } else if (event is AppendUserRouteLog) {
      var results = await api.logbookAdd(event.routeId, event.status);

      var newEntry = UserRouteLogEntry(
        event.routeId,
        event.grade,
        event.status,
        results["created_at"],
      );
      _entries[results["id"]] = newEntry;

      yield RouteLoadedWithImages(entries: _entries);
    }

    return;
  }

  @override
  void fetch() => add(FetchUserRouteLog());

  @override
  List<String> displayAttrs(entry) {
    return [entry.grade, entry.status, entry.createdAt];
  }

  @override
  int routeId(entryId, entry) => entry.routeId;

  @override
  Future<void> close() {
    routeImagesSubscription.cancel();
    return super.close();
  }
}