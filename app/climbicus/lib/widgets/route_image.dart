import 'package:climbicus/env.dart';
import 'package:climbicus/models/route_image.dart';
import 'package:climbicus/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:get_it/get_it.dart';

class RouteImageWidget extends StatelessWidget {
  final getIt = GetIt.instance;
  final RouteImage routeImage;

  RouteImageWidget(this.routeImage);

  @override
  Widget build(BuildContext context) {
    var imageWidget = (routeImage != null)
        ? Image.network(routeImage.path)
        : Image.asset("images/no_image.png");

    if (getIt<SettingsRepository>().env != Environment.dev) {
      return imageWidget;
    }

    var routeId = 0;
    var imageId = 0;
    if (routeImage != null) {
      routeId = routeImage.routeId;
      imageId = routeImage.id;
    }
    return Stack(
      children: <Widget>[
        imageWidget,
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
}
