import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:climbicus/models/user_route_votes.dart';


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

// TODO: fetch all, if needed, add optional routeId to fetch just one
class FetchUserRouteVotes extends UserRouteVotesEvent {}

class AddNewUserRouteVotes extends UserRouteVotesEvent {
  final int routeId;
  final double quality;
  final String difficulty;
  const AddNewUserRouteVotes({
    @required this.routeId,
    @required this.quality,
    @required this.difficulty,
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
  Map<int, UserRouteVotes> _entries = {};

  @override
  UserRouteVotesState get initialState => UserRouteVotesUninitialized();

  @override
  Stream<UserRouteVotesState> mapEventToState(UserRouteVotesEvent event) async* {
    if (event is FetchUserRouteVotes) {
      yield UserRouteVotesLoading();
      // TODO
    } else if (event is AddNewUserRouteVotes) {
      // TODO
    } else if (event is UpdateUserRouteVotes) {
      // TODO
    }

    return;
  }
}
