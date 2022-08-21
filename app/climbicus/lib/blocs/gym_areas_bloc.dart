import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:climbicus/models/area.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:climbicus/utils/images.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';


abstract class GymAreasState {
  const GymAreasState();
}

class GymAreasUninitialized extends GymAreasState {}

class GymAreasLoading extends GymAreasState {}

class GymAreasLoaded extends GymAreasState {
  final Map<int, Area> areas;
  const GymAreasLoaded({required this.areas});
}

class GymAreasError extends GymAreasState {
  FlutterErrorDetails errorDetails;

  GymAreasError({required Object exception, StackTrace? stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.reportError(errorDetails);
  }
}

abstract class GymAreasEvent {
  const GymAreasEvent();
}

class FetchGymAreas extends GymAreasEvent {}


class AddNewGymArea extends GymAreasEvent {
  final String? name;
  final File image;
  const AddNewGymArea({required this.name, required this.image});
}


class GymAreasBloc extends Bloc<GymAreasEvent, GymAreasState> {
  final getIt = GetIt.instance;

  Map<int, Area> _areas = {};

  GymAreasBloc() : super(GymAreasUninitialized());

  @override
  Stream<GymAreasState> mapEventToState(GymAreasEvent event) async* {
    if (event is FetchGymAreas) {
      yield GymAreasLoading();

      try {
        Map<String, dynamic> results = (await getIt<ApiRepository>().fetchAreas())["areas"];
        _areas = results.map((gymId, model) =>
            MapEntry(int.parse(gymId), Area.fromJson(model)));

        yield GymAreasLoaded(areas: _areas);
      } catch (e, st) {
        yield GymAreasError(exception: e, stackTrace: st);
      }
    } else if (event is AddNewGymArea) {
      yield GymAreasLoading();

      try {
        var compressedImage = await compressJpegImage(event.image);
        debugPrint("compressed photo size: ${compressedImage.lengthSync()} bytes");

        var results = (await getIt<ApiRepository>().areasAdd(compressedImage, event.name));
        var area = Area.fromJson(results["area"]);

        _areas[area.id] = area;

        yield GymAreasLoaded(areas: _areas);
      } catch (e, st) {
        yield GymAreasError(exception: e, stackTrace: st);
      }
    }
  }
}