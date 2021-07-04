
import 'dart:io';

import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/widgets/route_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../style.dart';
import 'add_route.dart';

class RouteMarkArgs {
  final ImagePickerData imgPickerData;
  final String routeCategory;

  RouteMarkArgs(this.imgPickerData, this.routeCategory);
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
    // TODO: use in-memory image instead
    return Column(
      children: [
        Expanded(
          child: Center(
            child: RoutePainter(
              canvasHeight: availableHeight(context, appBar),
              controller: _routePainterController,
              imageNetworkPath: widget.args.imgPickerData.routeImage.path,
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
    File localImage = await _routePainterController.save();

    Navigator.pushNamed(context, AddRoutePage.routeName,
      arguments: AddRouteArgs(widget.args.imgPickerData, widget.args.routeCategory, localImage),
    );
  }
}
