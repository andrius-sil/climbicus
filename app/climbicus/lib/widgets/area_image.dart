
import 'package:climbicus/models/area.dart';
import 'package:climbicus/models/route.dart' as jsonmdl;
import 'package:climbicus/widgets/route_image.dart';

import 'package:flutter/widgets.dart';

class AreaImageWidget extends StatefulWidget {
  final Area area;
  final List<jsonmdl.Route> routes;

  AreaImageWidget(this.area, this.routes);

  @override
  AreaImageWidgetState createState() => AreaImageWidgetState();
}

class AreaImageWidgetState extends State<AreaImageWidget> {
  @override
  Widget build(BuildContext context) {
    return RouteImageWidget.fromPath(widget.area.thumbnailImagePath);
  }

}
