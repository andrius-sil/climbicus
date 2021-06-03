

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
  final Users users;
  const UsersLoaded({required this.users});
}

class UsersError extends UsersState {
  FlutterErrorDetails errorDetails;

  UsersError({required Object exception, StackTrace? stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.reportError(errorDetails);
  }
}

abstract class UsersEvent {
  const UsersEvent();
}

class FetchUsers extends UsersEvent {
  final Set<int>? ids;

  FetchUsers([this.ids]);
}

class Users {
  final UsersBloc usersBloc;
  final Map<int, User> users;

  Users(this.usersBloc, this.users);

  bool loadResources(Set<int> ids) {
    var missingIds = ids.difference(users.keys.toSet());
    if (missingIds.isEmpty) {
      return true;
    }

    usersBloc.add(FetchUsers(missingIds));

    return false;
  }

  User? getResource(int id) => users[id];
}

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final getIt = GetIt.instance;

  Map<int, User> _users = {};

  UsersBloc() : super(UsersUninitialized()) {
    add(FetchUsers());
  }

  @override
  Stream<UsersState> mapEventToState(UsersEvent event) async* {
    if (event is FetchUsers) {
      yield UsersLoading();

      try {
        Map<String, dynamic> results =
            (await getIt<ApiRepository>().fetchUsers(event.ids))["users"];
        _users.addAll(results.map((userId, model) =>
            MapEntry(int.parse(userId), User.fromJson(model))));

        yield UsersLoaded(users: Users(this, _users));
      } catch (e, st) {
        yield UsersError(exception: e, stackTrace: st);
      }
    }
  }
}
