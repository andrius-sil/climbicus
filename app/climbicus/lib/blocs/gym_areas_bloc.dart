import 'package:bloc/bloc.dart';
import 'package:climbicus/models/area.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';


abstract class GymAreasState {
  const GymAreasState();
}

class GymAreasUninitialized extends GymAreasState {}

class GymAreasLoading extends GymAreasState {}

class GymAreasLoaded extends GymAreasState {
  final Map<int, Area> areas;
  const GymAreasLoaded({@required this.areas});
}

class GymAreasError extends GymAreasState {
  FlutterErrorDetails errorDetails;

  GymAreasError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.reportError(errorDetails);
  }
}

abstract class GymAreasEvent {
  const GymAreasEvent();
}

class FetchGymAreas extends GymAreasEvent {}

class GymAreasBloc extends Bloc<GymAreasEvent, GymAreasState> {
  final getIt = GetIt.instance;

  @override
  GymAreasState get initialState => GymAreasUninitialized();

  @override
  Stream<GymAreasState> mapEventToState(GymAreasEvent event) async* {
    if (event is FetchGymAreas) {
      yield GymAreasLoading();

      try {
        Map<String, dynamic> results = (await getIt<ApiRepository>().fetchAreas())["areas"];
        var areas = results.map((gymId, model) =>
            MapEntry(int.parse(gymId), Area.fromJson(model)));

        yield GymAreasLoaded(areas: areas);
      } catch (e, st) {
        yield GymAreasError(exception: e, stackTrace: st);
      }
    }
  }
}