import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/style.dart';
import 'package:climbicus/widgets/route_log.dart';
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

  final checkboxSentKey = GlobalKey<CheckboxWithTitleState>();
  final sliderAttemptsKey = GlobalKey<SliderAttemptsState>();

  RouteImagesBloc _routeImagesBloc;
  GymRoutesBloc _gymRoutesBloc;

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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text("Your route:"),
                      SizedBox(height: COLUMN_PADDING),
                      Container(
                        height: columnSize,
                        width: columnSize,
                        child: widget.takenImage,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text("Selected route:"),
                      SizedBox(height: COLUMN_PADDING),
                      Container(
                        height: columnSize,
                        width: columnSize,
                        child: widget.selectedImage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: <Widget>[
                CheckboxSent(key: checkboxSentKey),
                SliderAttempts(key: sliderAttemptsKey),
              ],
            ),
            RaisedButton(
              child: Text('Add'),
              onPressed: _logAndNavigateBack,
            ),
          ],
        ));
  }

  void _logAndNavigateBack() {
    _gymRoutesBloc.add(AddNewUserRouteLog(
      routeId: widget.selectedRouteId,
      completed: checkboxSentKey.currentState.value,
      numAttempts: sliderAttemptsKey.currentState.value,
    ));

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
