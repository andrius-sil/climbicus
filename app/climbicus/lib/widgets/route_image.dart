import 'package:climbicus/json/route_image.dart';
import 'package:flutter/material.dart';

class RouteImageWidget extends StatelessWidget {
  final RouteImage routeImage;

  const RouteImageWidget(this.routeImage);

  @override
  Widget build(BuildContext context) {
    var imageWidget = (routeImage != null)
        ? Image.network(routeImage.path)
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
