

import 'package:bloc/bloc.dart';
import 'package:climbicus/json/gym.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/foundation.dart';

abstract class GymsState {
  const GymsState();
}

class GymsUninitialized extends GymsState {}

class GymsLoading extends GymsState {}

class GymsLoaded extends GymsState {
  final Map<int, Gym> gyms;
  const GymsLoaded({@required this.gyms});
}

class GymsError extends GymsState {
  FlutterErrorDetails errorDetails;

  GymsError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.dumpErrorToConsole(errorDetails);
  }
}

abstract class GymsEvent {
  const GymsEvent();
}

class FetchGyms extends GymsEvent {}

class GymsBloc extends Bloc<GymsEvent, GymsState> {
  final ApiProvider api = ApiProvider();

  GymsBloc() {
    add(FetchGyms());
  }

  @override
  GymsState get initialState => GymsUninitialized();

  @override
  Stream<GymsState> mapEventToState(GymsEvent event) async* {
    if (event is FetchGyms) {
      yield GymsLoading();

      try {
        Map<String, dynamic> results = (await api.fetchGyms())["gyms"];
        var gyms = results.map((gymId, model) =>
            MapEntry(int.parse(gymId), Gym.fromJson(model)));

        yield GymsLoaded(gyms: gyms);
      } catch (e, st) {
        yield GymsError(exception: e, stackTrace: st);
      }
    }
  }
}