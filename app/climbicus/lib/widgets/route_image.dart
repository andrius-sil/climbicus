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
  static const boxFit = BoxFit.cover;

  final getIt = GetIt.instance;
  final RouteImage routeImage;
  final File imageFile;

  RouteImageWidget(this.routeImage) : imageFile = null;
  RouteImageWidget.fromFile(this.imageFile) : routeImage = null;

  @override
  Widget build(BuildContext context) {
    var imageWidget;
    if (imageFile != null) {
      imageWidget = Image.file(imageFile, fit: boxFit);
    } else if (routeImage != null) {
      imageWidget = Image(
        image: NetworkImageWithRetry(routeImage.path, fetchStrategy: _fetchStrategy),
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Image.asset("images/no_image.png");
    }
    var scaledImageWidget = ScaledImage(imageWidget);

    if (getIt<SettingsRepository>().env != Environment.dev) {
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
