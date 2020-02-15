
import 'dart:io';

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


class ImagePickerResults {
  final File image;
  final Future<Map> predictions;

  const ImagePickerResults(this.image, this.predictions);
}


class RouteImagePicker {
  final ApiProvider api = ApiProvider();

  Future<ImagePickerResults> pickImage(ImageSource imageSource) async {
    var image = await ImagePicker.pickImage(
      source: imageSource,
      maxWidth: 1028,
      imageQuality: 76,
    );

    if (image == null) {
      return null;
    }

    debugPrint("photo size: ${image.lengthSync()} bytes ($imageSource)");

    var predictions = api.uploadRouteImage(image);
    return ImagePickerResults(image, predictions);
  }

}
