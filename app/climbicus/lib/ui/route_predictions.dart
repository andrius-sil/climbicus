
import 'dart:convert';
import 'dart:typed_data';

import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:flutter/material.dart';

class RoutePredictionsPage extends StatefulWidget {
  final Api api;
  final ImagePickerResults results;

  const RoutePredictionsPage({this.api, this.results});

  @override
  State<StatefulWidget> createState() => _RoutePredictionsPageState();
}

class _RoutePredictionsPageState extends State<RoutePredictionsPage> {
  static const double columnHeight = 100;
  static const int displayPredictionsNum = 3;

  Future<Map> images;

  List<int> routeIds;

  @override
  void initState() {
    super.initState();

    images = fetchRouteImages(widget.results.predictions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your route'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text("Your photo:"),
            Image.file(widget.results.image),
            Row(
              children: <Widget>[
                Expanded(
                  child: FutureBuilder<Map>(
                    future: images,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _buildLogbookImagesView(snapshot.data);
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }

                      return CircularProgressIndicator();
                    },
                  )
                ),
                Expanded(
                  child: FutureBuilder<Map>(
                    future: widget.results.predictions,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _buildLogbookView(snapshot.data);
                      } else if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }

                      return CircularProgressIndicator();
                    },
                  ),
                ),
              ],
            ),
          ]),
      ),
    );
  }

  Widget _buildLogbookView(Map data) {
    List<Widget> widgets = [];
    for (var i = 0; i < displayPredictionsNum; i++) {
      var prediction = data["sorted_route_predictions"][i];
      widgets.add(
        Container(
          height: columnHeight,
          alignment: Alignment.center,
          child: Column(
            children: <Widget>[
              Expanded(child: Text(prediction["route_id"].toString())),
              Expanded(child: Text(prediction["grade"])),
            ],
          )
        )
      );
    }

    return ListView(
        children: widgets,
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
    );
  }

  Widget _buildLogbookImagesView(Map data) {
    List<Widget> widgets = [];

    routeIds.forEach((id) {
      var fields = data["route_images"][id.toString()];

      var w;
      if (fields != null) {
        Uint8List bytes = base64.decode(fields);
        w = Image.memory(bytes);
      } else {
        w = Text("No image '$id'");
      }
      widgets.add(
          Container(
            height: columnHeight,
            alignment: Alignment.center,
            child: w,
          )
      );

    });

    return ListView(
      children: widgets,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
    );
  }

  Future<Map> fetchRouteImages(Future<Map> predictions) async {
    var p = await predictions;
    routeIds = List.generate(
        displayPredictionsNum,
            (i) => p["sorted_route_predictions"][i]["route_id"]
    );

    return widget.api.fetchRouteImages(routeIds);
  }

}
