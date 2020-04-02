import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/json/prediction.dart';
import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

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

class RoutePredictionLoadedWithImages extends RoutePredictionLoaded {
  const RoutePredictionLoadedWithImages({imgPickerData}) : super(imgPickerData: imgPickerData);
}

class RoutePredictionError extends RoutePredictionState {
  FlutterErrorDetails errorDetails;

  RoutePredictionError({Exception exception, StackTrace stackTrace}):
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

class UpdateRoutePrediction extends RoutePredictionEvent {}


class RoutePredictionBloc extends Bloc<RoutePredictionEvent, RoutePredictionState> {
  static const String TRIGGER = "RoutePredictionBloc";

  final ApiProvider api = ApiProvider();
  final RouteImagesBloc routeImagesBloc;

  ImagePickerData _imgPickerData;
  StreamSubscription routeImagesSubscription;

  RoutePredictionBloc({this.routeImagesBloc}) {
    routeImagesSubscription = routeImagesBloc.listen((state) {
      if (state is RouteImagesLoaded && state.trigger == TRIGGER) {
        add(UpdateRoutePrediction());
      }
    });
  }

  @override
  RoutePredictionState get initialState => RoutePredictionUninitialized();

  @override
  Stream<RoutePredictionState> mapEventToState(RoutePredictionEvent event) async* {
    if (event is FetchRoutePrediction) {
      yield RoutePredictionLoading();

      try {
        var imageAndPredictions = (await api.routePredictions(event.image));
        List<dynamic> predictions = imageAndPredictions["sorted_route_predictions"];
        _imgPickerData = ImagePickerData(
          RouteImage.fromJson(imageAndPredictions["route_image"]),
          event.image,
          predictions.map((model) => Prediction.fromJson(model)).toList(),
        );

        var routeIds = _routeIds(_imgPickerData.predictions, event.displayPredictionsNum);
        routeImagesBloc.add(FetchRouteImages(routeIds: routeIds, trigger: TRIGGER));

        yield RoutePredictionLoaded(imgPickerData: _imgPickerData);
      } catch (e, st) {
        yield RoutePredictionError(exception: e, stackTrace: st);
      }
    } else if (event is UpdateRoutePrediction) {
      yield RoutePredictionLoadedWithImages(imgPickerData: _imgPickerData);
    }

    return;
  }

  @override
  Future<void> close() {
    routeImagesSubscription.cancel();
    return super.close();
  }

  List<int> _routeIds(List<Prediction> predictions, int displayPredictionsNum) {
    List<int> routeIds = List.generate(displayPredictionsNum, (i) => predictions[i].routeId);
    return routeIds;
  }
}
