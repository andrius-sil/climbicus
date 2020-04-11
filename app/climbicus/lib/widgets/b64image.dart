import 'dart:convert';

import 'package:climbicus/json/route_image.dart';
import 'package:flutter/material.dart';

class B64Image extends StatelessWidget {
  final RouteImage routeImage;

  const B64Image(this.routeImage);

  @override
  Widget build(BuildContext context) {
    var imageWidget = (routeImage != null)
        ? Image.memory(base64.decode(routeImage.b64Image))
        : Image.asset("images/no_image.png");

    return imageWidget;
//    var routeId = 0;
//    var imageId = 0;
//    if (routeImage != null) {
//      routeId = routeImage.routeId;
//      imageId = routeImage.id;
//    }
//    return Stack(
//      children: <Widget>[
//        imageWidget,
//        Align(
//          alignment: Alignment.bottomLeft,
//          child: Text("route_id: $routeId. routeId, image_id: $imageId"),
//        ),
//      ],
//    );
  }
}
