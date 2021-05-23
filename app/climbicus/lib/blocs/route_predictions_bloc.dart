import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:bloc/bloc.dart';
import 'package:climbicus/models/route.dart' as jsonmdl;
import 'package:climbicus/models/route_image.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:climbicus/utils/io.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get_it/get_it.dart';

class Prediction {
  jsonmdl.Route route;
  RouteImage routeImage;
  Prediction({required this.route, required this.routeImage});
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
  const RoutePredictionLoaded({required this.imgPickerData});
}

class RoutePredictionError extends RoutePredictionState {
  FlutterErrorDetails errorDetails;

  RoutePredictionError({required Object exception, StackTrace? stackTrace}):
        errorDetails = FlutterErrorDetails(exception: exception, stack: stackTrace) {
    FlutterError.reportError(errorDetails);
  }
}

abstract class RoutePredictionEvent {
  const RoutePredictionEvent();
}

class FetchRoutePrediction extends RoutePredictionEvent {
  final File image;
  final String routeCategory;
  const FetchRoutePrediction({required this.image, required this.routeCategory});
}


class RoutePredictionBloc extends Bloc<RoutePredictionEvent, RoutePredictionState> {
  final getIt = GetIt.instance;

  late ImagePickerData _imgPickerData;

  RoutePredictionBloc() : super(RoutePredictionUninitialized());

  @override
  Stream<RoutePredictionState> mapEventToState(RoutePredictionEvent event) async* {
    if (event is FetchRoutePrediction) {
      yield RoutePredictionLoading();

      try {
        var dirPath = await routePicturesDir();
        var compressedImage = await (FlutterImageCompress.compressAndGetFile(
          event.image.absolute.path,
          p.join(dirPath, "compressed_${p.basename(event.image.path)}"),
          minWidth: 1024,
          quality: 75,
        ));
        debugPrint("compressed photo size: ${compressedImage!.lengthSync()} bytes");

        var imageAndPredictions = (await getIt<ApiRepository>().routePredictions(compressedImage, event.routeCategory));
        List<dynamic> predictions = imageAndPredictions["sorted_route_and_image_predictions"];
        _imgPickerData = ImagePickerData(
          RouteImage.fromJson(imageAndPredictions["route_image"]),
          compressedImage,
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
