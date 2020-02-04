import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:climbicus/ui/route_predictions.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LogbookPage extends StatefulWidget {
  final AppBar appBar;
  final Api api;

  RouteImagePicker imagePicker;

  LogbookPage({this.appBar, this.api}) {
     imagePicker = new RouteImagePicker(api: api);
  }

  @override
  State<StatefulWidget> createState() => _LogbookPageState();
}

class _LogbookPageState extends State<LogbookPage> {
  static const double columnHeight = 100;

  Future<Map> entries;
  Future<Map> images;

  List<int> routeIds;

  @override
  void initState() {
    super.initState();

    entries = widget.api.fetchLogbook();
    images = fetchRouteImages(entries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: Row (
        children: <Widget>[
          Expanded(
            child: FutureBuilder<Map>(
              future: entries,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _buildLogbookView(snapshot.data);
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }

                return CircularProgressIndicator();
              },
            )
          ),
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
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () async {
              var results = await widget.imagePicker.getGalleryImage();
              Navigator.push(context, MaterialPageRoute(
                builder: (BuildContext context) {
                  return RoutePredictionsPage(api: widget.api, results: results);
                },
              ));
            },
            tooltip: 'Pick image (gallery)',
            child: Icon(Icons.add_photo_alternate),
            heroTag: "btnGallery",
          ),
          SizedBox(
            height: 16.0,
          ),
          FloatingActionButton(
            onPressed: () => widget.imagePicker.getCameraImage(),
            tooltip: 'Pick image (camera)',
            child: Icon(Icons.add_a_photo),
            heroTag: "btnCamera",
          ),
        ],
      ),
    );
  }

  Widget _buildLogbookView(Map data) {
    List<Widget> widgets = [];
    var sortedData = _sortEntriesByLogDate(data);
    sortedData.forEach((id, fields) {
      widgets.add(
        Container(
          height: columnHeight,
          alignment: Alignment.center,
          child: Column(
            children: <Widget>[
              Text(fields["grade"]),
              Text(fields["status"]),
              Text(fields["created_at"]),
            ],
          )
        )
      );
    });

    return ListView(children: widgets);
  }

  Widget _buildLogbookImagesView(Map data) {
    List<Widget> widgets = [];

    routeIds.forEach((id) {
      var fields = data["route_images"][id.toString()];

      var w;
      if (fields != null) {
        Uint8List bytes = base64.decode(fields["b64_image"]);
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

    return ListView(children: widgets);
  }

  Future<Map> fetchRouteImages(Future<Map> entries) async {
    routeIds = [];
    _sortEntriesByLogDate(await entries).forEach((id, fields) {
      routeIds.add(fields["route_id"]);
    });

    return widget.api.fetchRouteImages(routeIds);
  }

  LinkedHashMap _sortEntriesByLogDate(Map entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort((k1, k2) => entries[k1]["created_at"].compareTo(entries[k2]["created_at"]));

    return new LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => entries[k]);
  }
}
