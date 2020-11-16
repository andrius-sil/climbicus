import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:climbicus/models/user_route_votes.dart';
import 'package:get_it/get_it.dart';


class UserRouteVotesData {
  final double quality;
  final String difficulty;
  const UserRouteVotesData(this.quality, this.difficulty);
}


abstract class UserRouteVotesState {
  const UserRouteVotesState();
}

class UserRouteVotesUninitialized extends UserRouteVotesState {}

class UserRouteVotesLoading extends UserRouteVotesState {}

class UserRouteVotesLoaded extends UserRouteVotesState {
  final Map<int, UserRouteVotes> entries;
  const UserRouteVotesLoaded({@required this.entries}) ;
}

class UserRouteVotesError extends UserRouteVotesState {
  FlutterErrorDetails errorDetails;

  UserRouteVotesError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.dumpErrorToConsole(errorDetails);
  }
}

abstract class UserRouteVotesEvent {
  const UserRouteVotesEvent();
}

class FetchUserRouteVotes extends UserRouteVotesEvent {}

class AddNewUserRouteVotes extends UserRouteVotesEvent {
  final int routeId;
  final UserRouteVotesData userRouteVotesData;
  const AddNewUserRouteVotes({
    @required this.routeId,
    @required this.userRouteVotesData,
  });
}

class UpdateUserRouteVotes extends UserRouteVotesEvent {
  final int userRouteVotesId;
  final double quality;
  final String difficulty;
  const UpdateUserRouteVotes({
    @required this.userRouteVotesId,
    @required this.quality,
    @required this.difficulty,
  });
}


class UserRouteVotesBloc extends Bloc<UserRouteVotesEvent, UserRouteVotesState> {
  final getIt = GetIt.instance;

  Map<int, UserRouteVotes> _entries = {};

  @override
  UserRouteVotesState get initialState => UserRouteVotesUninitialized();

  @override
  Stream<UserRouteVotesState> mapEventToState(UserRouteVotesEvent event) async* {
    if (event is FetchUserRouteVotes) {
      yield UserRouteVotesLoading();

      try {
        _entries = await getIt<ApiRepository>().fetchUserRouteVotes();
        // TODO: parse entries?
        yield UserRouteVotesLoaded(entries: _entries);
      } catch (e, st) {
        yield UserRouteVotesError(exception: e, stackTrace: st);
      }
    } else if (event is AddNewUserRouteVotes) {
      var results = await getIt<ApiRepository>().userRouteVotesAdd(
          event.routeId,
          event.userRouteVotesData.quality,
          event.userRouteVotesData.difficulty,
      );
      var newUserRouteVotes = UserRouteVotes.fromJson(results["user_route_votes"]);

      _entries[newUserRouteVotes.id] = newUserRouteVotes;

      yield UserRouteVotesLoaded(entries: _entries);
    } else if (event is UpdateUserRouteVotes) {
      var results = await getIt<ApiRepository>().userRouteVotesUpdate(event.userRouteVotesId, event.quality, event.difficulty);
      var updatedUserRouteVotes = UserRouteVotes.fromJson(results["user_route_votes"]);

      _entries[updatedUserRouteVotes.id] = updatedUserRouteVotes;

      yield UserRouteVotesLoaded(entries: _entries);
    }

    return;
  }
}
