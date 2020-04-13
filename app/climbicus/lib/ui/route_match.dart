import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteMatchPage extends StatefulWidget {
  final int selectedRouteId;
  final Widget selectedImage;
  final int takenRouteImageId;
  final Image takenImage;

  RouteMatchPage({
    this.selectedRouteId,
    this.selectedImage,
    this.takenRouteImageId,
    this.takenImage,
  });

  @override
  State<StatefulWidget> createState() => _RouteMatchPageState();
}

class _RouteMatchPageState extends State<RouteMatchPage> {
  static const double columnSize = 200.0;

  RouteImagesBloc _routeImagesBloc;
  GymRoutesBloc _gymRoutesBloc;

  bool _selectedCompleted = false;
  double _selectedNumAttempts;

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _gymRoutesBloc = BlocProvider.of<GymRoutesBloc>(context);

    _routeImagesBloc.add(UpdateRouteImage(
      routeId: widget.selectedRouteId,
      routeImageId: widget.takenRouteImageId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your ascent'),
        ),
        body: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: Column(
                  children: <Widget>[
                    Text("Your photo:"),
                    Container(
                      color: Colors.white,
                      height: columnSize,
                      width: columnSize,
                      child: widget.takenImage,
                    ),
                  ],
                )),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text("Selected photo:"),
                      Container(
                        color: Colors.white,
                        height: columnSize,
                        width: columnSize,
                        child: widget.selectedImage,
                      ),
                    ],
                ),
                ),
              ],
            ),
            Text("sent clean?"),
            Checkbox(
              value: _selectedCompleted,
              onChanged: (bool value) {
                setState(() {
                  _selectedCompleted = value;
                });
              },
            ),
            Text("how many attempts?"),
            Text("${_numAttemptsLabel()}"),
            Slider(
              value: (_selectedNumAttempts == null) ? 0.0 : _selectedNumAttempts,
              min: 0.0,
              max: 30.0,
              divisions: 30,
              label: _numAttemptsLabel(),
              onChanged: (double value) => setState(() {
                (value == 0.0) ?
                    _selectedNumAttempts = null :
                    _selectedNumAttempts = value;
              }),
            ),
            RaisedButton(
              child: Text('Log it'),
              onPressed: _logAndNavigateBack,
            ),
          ],
        ));
  }

  String _numAttemptsLabel() {
    return (_selectedNumAttempts == null) ?
        "--" :
        "${_selectedNumAttempts.toInt()}";
  }

  void _logAndNavigateBack() {
    _gymRoutesBloc.add(AddNewUserRouteLog(
      routeId: widget.selectedRouteId,
      completed: _selectedCompleted,
      numAttempts: (_selectedNumAttempts == null) ? null : _selectedNumAttempts.toInt(),
    ));

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
