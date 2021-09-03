import 'package:climbicus/models/area.dart';
import 'package:climbicus/widgets/route_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../style.dart';
import 'add_route.dart';

class RouteMarkArgs {
  final Area area;
  final String routeCategory;

  RouteMarkArgs(this.area, this.routeCategory);
}

class RouteMarkPage extends StatefulWidget {
  static const routeName = '/route_mark';

  final RouteMarkArgs args;

  RouteMarkPage(this.args);

  @override
  State<StatefulWidget> createState() => _RouteMarkPageState();
}

class _RouteMarkPageState extends State<RouteMarkPage> {
  late RoutePainterController _routePainterController;

  @override
  void initState() {
    super.initState();

    _routePainterController = RoutePainterController();
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      title: const Text('Mark holds'),
    );

    return Scaffold(
      appBar: appBar,
      body: _buildPainter(appBar),
    );
  }

  Widget _buildPainter(AppBar appBar) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: RoutePainter(
              availableWidth: MediaQuery.of(context).size.width,
              availableHeight: availableHeight(context, appBar),
              controller: _routePainterController,
              imageNetworkPath: widget.args.area.imagePath,
            ),
          ),
        ),
        ElevatedButton(
          child: Text("Finished"),
          onPressed: _onFinished,
        ),
      ],
    );
  }

  Future<void> _onFinished() async {
    var paintedRouteImage = await _routePainterController.save();

    Navigator.pushNamed(context, AddRoutePage.routeName,
      arguments: AddRouteArgs(widget.args.area, paintedRouteImage, widget.args.routeCategory),
    );
  }
}
