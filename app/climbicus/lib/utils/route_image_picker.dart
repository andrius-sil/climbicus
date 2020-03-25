import 'dart:io';

import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

class RouteImagePicker {

  Future<File> pickImage(ImageSource imageSource,
      RouteImagesBloc routeImagesBloc) async {
    var image = await ImagePicker.pickImage(
      source: imageSource,
      maxWidth: 1028,
      imageQuality: 76,
    );

    if (image != null) {
      debugPrint("photo size: ${image.lengthSync()} bytes ($imageSource)");
      return image;
    }

    return null;
  }
}
