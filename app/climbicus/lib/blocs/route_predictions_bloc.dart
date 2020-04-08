import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:climbicus/json/route.dart' as jsonmdl;
import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

class Prediction {
  jsonmdl.Route route;
  RouteImage routeImage;
  Prediction({this.route, this.routeImage});
}

class ImagePickerData {
  final RouteImage routeImage;
  final File image;
  final List<Prediction> predictions;

  const ImagePickerData(this.routeImage, this.image, this.predictions);
}

abstract class RoutePredictionState {
  const RoutePredictionState();
}

class RoutePredictionUninitialized extends RoutePredictionState {}

class RoutePredictionLoading extends RoutePredictionState {}

class RoutePredictionLoaded extends RoutePredictionState {
  final ImagePickerData imgPickerData;
  const RoutePredictionLoaded({this.imgPickerData});
}

class RoutePredictionError extends RoutePredictionState {
  FlutterErrorDetails errorDetails;

  RoutePredictionError({Object exception, StackTrace stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.dumpErrorToConsole(errorDetails);
  }
}

abstract class RoutePredictionEvent {
  const RoutePredictionEvent();
}

class FetchRoutePrediction extends RoutePredictionEvent {
  final File image;
  final int displayPredictionsNum;
  const FetchRoutePrediction({this.image, this.displayPredictionsNum});
}


class RoutePredictionBloc extends Bloc<RoutePredictionEvent, RoutePredictionState> {
  static const String TRIGGER = "RoutePredictionBloc";

  final ApiProvider api = ApiProvider();

  ImagePickerData _imgPickerData;

  @override
  RoutePredictionState get initialState => RoutePredictionUninitialized();

  @override
  Stream<RoutePredictionState> mapEventToState(RoutePredictionEvent event) async* {
    if (event is FetchRoutePrediction) {
      yield RoutePredictionLoading();

      try {
        var imageAndPredictions = (await api.routePredictions(event.image));
        List<dynamic> predictions = imageAndPredictions["sorted_route_and_image_predictions"];
        _imgPickerData = ImagePickerData(
          RouteImage.fromJson(imageAndPredictions["route_image"]),
          event.image,
          predictions.map((model) => Prediction(
              route: jsonmdl.Route.fromJson(model["route"]),
              routeImage: RouteImage.fromJson(model["route_image"]),
          )).toList(),
        );
        yield RoutePredictionLoaded(imgPickerData: _imgPickerData);
      } catch (e, st) {
        yield RoutePredictionError(exception: e, stackTrace: st);
      }
    }

    return;
  }
}
