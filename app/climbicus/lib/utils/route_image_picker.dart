import 'dart:io';

import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/json/prediction.dart';
import 'package:climbicus/json/route_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';

const Map<ImageSource, Map<String, dynamic>> IMAGE_SOURCES = {
  ImageSource.gallery: {
    "tooltip": "Pick image (gallery)",
    "heroTag": "btnGallery",
    "icon": Icons.add_photo_alternate,
  },
  ImageSource.camera: {
    "tooltip": "Pick image (camera)",
    "heroTag": "btnCamera",
    "icon": Icons.add_a_photo,
  },
};

class ImagePickerData {
  final RouteImage routeImage;
  final File image;
  final List<Prediction> predictions;

  const ImagePickerData(this.routeImage, this.image, this.predictions);
}

class RouteImagePicker {
  final ApiProvider api = ApiProvider();

  Future<ImagePickerData> pickImage(ImageSource imageSource,
      RouteImagesBloc routeImagesBloc) async {
    var image = await ImagePicker.pickImage(
      source: imageSource,
      maxWidth: 1028,
      imageQuality: 76,
    );

    if (image == null) {
      return null;
    }

    debugPrint("photo size: ${image.lengthSync()} bytes ($imageSource)");

    var imageAndPredictions = (await api.routePredictions(image));
    List<dynamic> predictions = imageAndPredictions["sorted_route_predictions"];
    return ImagePickerData(
      RouteImage(
          imageAndPredictions["route_image_id"],
          imageAndPredictions["b64_image"]
      ),
      image,
      predictions.map((model) => Prediction.fromJson(model)).toList(),
    );
  }
}
