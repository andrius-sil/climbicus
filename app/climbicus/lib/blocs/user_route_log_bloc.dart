import 'dart:async';

import 'package:climbicus/blocs/route_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/json/user_route_log.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/time.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class UserRouteLogEntry {
  UserRouteLog userRouteLog;
  String grade;
  DateTime createdAt;
  int userId;
  UserRouteLogEntry({this.userRouteLog, this.grade}) :
        createdAt = userRouteLog.createdAt,
        userId = userRouteLog.userId;
}

abstract class UserRouteLogEvent {
  const UserRouteLogEvent();
}

class FetchUserRouteLog extends UserRouteLogEvent {
  final int routeId;
  const FetchUserRouteLog({this.routeId});
}

class AddNewUserRouteLog extends UserRouteLogEvent {
  final int routeId;
  final String status;
  const AddNewUserRouteLog({this.routeId, this.status});
}

class UpdateUserRouteLog extends UserRouteLogEvent {}


class UserRouteLogBloc extends RouteBloc<UserRouteLogEvent, RouteState> {
  static const String TRIGGER = "UserRouteLogBloc";

  final ApiProvider api = ApiProvider();
  final RouteImagesBloc routeImagesBloc;

  Map<int, UserRouteLogEntry> _entries = {};
  StreamSubscription _routeImagesSubscription;

  UserRouteLogBloc({@required this.routeImagesBloc}) {
    _routeImagesSubscription = routeImagesBloc.listen((state) {
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
        var data;
        if (event.routeId != null) {
          // TODO: avoid redundant fetches if logbook already contains routeId
          data = api.fetchLogbookOneRoute(event.routeId);
        } else {
          data = api.fetchLogbook();
        }

        Map<String, dynamic> logbook = (await data);
        var newEntries = logbook.map((userRouteLogId, model) =>
            MapEntry(int.parse(userRouteLogId), UserRouteLogEntry(userRouteLog: UserRouteLog.fromJson(model["user_route_log"]), grade: model["grade"])));
        _entries.addAll(newEntries);

        var routeIds = _entries.values.map((entry) => entry.userRouteLog.routeId).toList();
        routeImagesBloc.add(FetchRouteImages(routeIds: routeIds, trigger: TRIGGER));

        yield RouteLoaded(entries: _entries);
      } catch (e, st) {
        yield RouteError(exception: e, stackTrace: st);
      }
    } else if (event is UpdateUserRouteLog) {
      yield RouteLoadedWithImages(entries: _entries);
    } else if (event is AddNewUserRouteLog) {
      var results = await api.logbookAdd(event.routeId, event.status);
      var newUserRouteLog = UserRouteLog.fromJson(results["user_route_log"]);

      _entries[newUserRouteLog.id] = UserRouteLogEntry(
        userRouteLog: newUserRouteLog,
        grade: "1a", // TODO: replace with actual grade
      );

      yield RouteLoadedWithImages(entries: _entries);
    }

    return;
  }

  @override
  void fetch() => add(FetchUserRouteLog());

  @override
  String headerTitle(entry) {
    return "${entry.grade} - ${entry.userRouteLog.status}";
  }

  @override
  String bodyTitle(entry) {
    return "${dateAndTimeToString(entry.userRouteLog.createdAt)}";
  }

  @override
  String bodySubtitle(entry) {
    return "added by 'user ${entry.userRouteLog.userId.toString()}'";
  }

  @override
  int routeId(entryId, entry) => entry.userRouteLog.routeId;

  @override
  Future<void> close() {
    _routeImagesSubscription.cancel();
    return super.close();
  }
}
