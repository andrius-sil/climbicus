import 'package:bloc/bloc.dart';
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

abstract class UserRouteLogState {
  const UserRouteLogState();
}

class UserRouteLogUninitialized extends UserRouteLogState {}

class UserRouteLogLoading extends UserRouteLogState {}

class UserRouteLogLoaded extends UserRouteLogState {
  final Map<int, Map<int, UserRouteLog>> userRouteLogs;
  const UserRouteLogLoaded({@required this.userRouteLogs});
}

class UserRouteLogError extends UserRouteLogState {
  FlutterErrorDetails errorDetails;

  UserRouteLogError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.reportError(errorDetails);
  }
}

abstract class UserRouteLogEvent {
  const UserRouteLogEvent();
}

class FetchUserRouteLog extends UserRouteLogEvent {
  final int routeId;

  const FetchUserRouteLog({@required this.routeId});
}

class UserRouteLogBloc extends Bloc<UserRouteLogEvent, UserRouteLogState> {
  final getIt = GetIt.instance;

  Map<int, Map<int, UserRouteLog>> userRouteLogs = {};

  @override
  UserRouteLogState get initialState => UserRouteLogUninitialized();

  @override
  Stream<UserRouteLogState> mapEventToState(UserRouteLogEvent event) async* {
    if (event is FetchUserRouteLog) {
      yield UserRouteLogLoading();

      try {
        var dataLogbook = getIt<ApiRepository>().fetchLogbookOneRoute(event.routeId);
        var routeLogbook = (await dataLogbook).map((userRouteLogId, model) =>
            MapEntry(int.parse(userRouteLogId), UserRouteLog.fromJson(model)));
        userRouteLogs[event.routeId] = routeLogbook;

        yield UserRouteLogLoaded(userRouteLogs: userRouteLogs);
      } catch (e, st) {
        yield UserRouteLogError(exception: e, stackTrace: st);
      }
    }
  }
}
