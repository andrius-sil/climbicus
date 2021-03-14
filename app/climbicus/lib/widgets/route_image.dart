import 'dart:io';

import 'package:climbicus/env.dart';
import 'package:climbicus/models/route_image.dart';
import 'package:climbicus/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_image/network.dart';
import 'package:get_it/get_it.dart';

class RouteImageWidget extends StatelessWidget {
  // Determines how to display scaled image.
  static const defaultBoxFit = BoxFit.cover;

  final getIt = GetIt.instance;
  final RouteImage routeImage;
  final File imageFile;

  String imagePath;
  BoxFit boxFit = defaultBoxFit;

  RouteImageWidget(this.routeImage) :
    imageFile = null,
    imagePath = null;
  RouteImageWidget.fromFile(this.imageFile) :
    routeImage = null,
    imagePath = null;
  RouteImageWidget.fromPath(this.imagePath, {boxFit = defaultBoxFit}) :
    routeImage = null,
    imageFile = null,
    boxFit = boxFit;

  @override
  Widget build(BuildContext context) {
    var imageWidget;
    if (imageFile != null) {
      imageWidget = Image.file(imageFile, fit: boxFit);
    } else if (routeImage != null || imagePath != null) {
      imagePath ??= routeImage.path;

      imageWidget = Image(
        image: NetworkImageWithRetry(imagePath, fetchStrategy: _fetchStrategy),
        fit: boxFit,
      );
    } else {
      imageWidget = Image.asset("images/no_image.png");
    }
    var scaledImageWidget = ScaledImage(imageWidget);

    // TODO: use env var
    // var debug = getIt<SettingsRepository>().env == Environment.dev;
    var debug = false;
    if (!debug) {
      return scaledImageWidget;
    }

    var routeId = 0;
    var imageId = 0;
    if (routeImage != null) {
      routeId = routeImage.routeId;
      imageId = routeImage.id;
    }
    return Stack(
      children: <Widget>[
        scaledImageWidget,
        Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            "route_id: $routeId\nimage_id: $imageId",
            style: TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  static final FetchStrategy _fetchStrategy = const FetchStrategyBuilder(
    transientHttpStatusCodePredicate: _transientHttpStatusCodePredicate,
  ).build();

  static bool _transientHttpStatusCodePredicate(int statusCode) {
    return _transientHttpStatusCodes.contains(statusCode);
  }

  static const List<int> _transientHttpStatusCodes = <int>[
    0,   // Network error
    403, // Forbidden (returned by CloudFront if image hasn't been uploaded yet)
    408, // Request timeout
    500, // Internal server error
    502, // Bad gateway
    503, // Service unavailable
    504 // Gateway timeout
  ];
}


class ScaledImage extends StatelessWidget {
  final Image image;

  ScaledImage(this.image);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      child: image,
      aspectRatio: 1,
    );
  }
}
