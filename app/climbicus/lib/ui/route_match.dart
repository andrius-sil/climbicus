import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RouteMatchPage extends StatefulWidget {
  final ApiProvider api = ApiProvider();

  final int selectedRouteId;
  final Image selectedImage;
  final int takenRouteImageId;
  final Image takenImage;
  final String grade;

  RouteMatchPage({
    this.selectedRouteId,
    this.selectedImage,
    this.takenRouteImageId,
    this.takenImage,
    this.grade,
  });

  @override
  State<StatefulWidget> createState() => _RouteMatchPageState();
}

class _RouteMatchPageState extends State<RouteMatchPage> {
  static const double columnSize = 200.0;

  @override
  void initState() {
    super.initState();

    widget.api.routeMatch(
      widget.selectedRouteId,
      widget.takenRouteImageId,
      true,
    );
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

                Provider.of<UserRouteLogModel>(context, listen: false)
                    .add(widget.selectedRouteId, widget.grade, value);

                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            )
          ],
        ));
  }
}
