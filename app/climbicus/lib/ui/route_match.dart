import 'package:climbicus/blocs/gym_routes_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteMatchPage extends StatefulWidget {
  final int selectedRouteId;
  final Image selectedImage;
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
                )),
              ],
            ),
            Text("Select status"),
            DropdownButton<String>(
              value: "not selected",
              items: <String>[
                "not selected",
                "flash",
                "red-point",
                "did not finish"
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String value) {
                if (value == "not selected") {
                  return;
                }

                _gymRoutesBloc.add(AddNewUserRouteLog(
                    routeId: widget.selectedRouteId,
                    status: value,
                ));

                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            )
          ],
        ));
  }
}
