

import 'package:bloc/bloc.dart';
import 'package:climbicus/models/user.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

abstract class UsersState {
  const UsersState();
}

class UsersUninitialized extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final Map<int, User> users;
  const UsersLoaded({@required this.users});
}

class UsersError extends UsersState {
  FlutterErrorDetails errorDetails;

  UsersError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.dumpErrorToConsole(errorDetails);
  }
}

abstract class UsersEvent {
  const UsersEvent();
}

class FetchUsers extends UsersEvent {}

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final getIt = GetIt.instance;

  UsersBloc() {
    add(FetchUsers());
  }

  @override
  UsersState get initialState => UsersUninitialized();

  @override
  Stream<UsersState> mapEventToState(UsersEvent event) async* {
    if (event is FetchUsers) {
      yield UsersLoading();

      try {
        Map<String, dynamic> results = (await getIt<ApiRepository>().fetchUsers())["users"];
        var users = results.map((userId, model) =>
            MapEntry(int.parse(userId), User.fromJson(model)));

        yield UsersLoaded(users: users);
      } catch (e, st) {
        yield UsersError(exception: e, stackTrace: st);
      }
    }
  }
}
