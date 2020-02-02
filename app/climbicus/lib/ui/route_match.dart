
import 'package:climbicus/utils/api.dart';
import 'package:flutter/material.dart';

class RouteMatchPage extends StatefulWidget {
  final Api api;
  final int selectedRouteId;
  final Image selectedImage;
  final Image takenImage;

  const RouteMatchPage({
    this.api,
    this.selectedRouteId,
    this.selectedImage,
    this.takenImage,
  });

  @override
  State<StatefulWidget> createState() => _RouteMatchPageState();
}

class _RouteMatchPageState extends State<RouteMatchPage> {
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
                      widget.takenImage,
                    ],
                  )
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text("Selected photo:"),
                      widget.selectedImage,
                    ],
                  )
                ),
              ],
            ),
            Text("Select status"),
            DropdownButton<String>(
              value: "not selected",
              items: <String>["not selected", "flash", "red-point", "did not finish"]
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
              }).toList(),
              onChanged: (String value) {
                if (value == "not selected") {
                  return;
                }
              },
            )
          ],
        )
    );
  }

}
