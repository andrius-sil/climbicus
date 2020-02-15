import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:climbicus/ui/route_predictions.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class LogbookPage extends StatefulWidget {
  final ApiProvider api = ApiProvider();
  final RouteImagePicker imagePicker = RouteImagePicker();
  final Settings settings = Settings();
  final AppBar appBar;

  LogbookPage({this.appBar});

  @override
  State<StatefulWidget> createState() => _LogbookPageState();
}

class _LogbookPageState extends State<LogbookPage> {
  static const double columnHeight = 100.0;
  static const double columnWidth = 100.0;

  Future<Map> entries;
  Future<Map> images;

  @override
  void initState() {
    super.initState();

    entries = widget.api.fetchLogbook();
    images = _fetchRouteImages(entries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([entries, images]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildLogbookGrid(snapshot.data[0], snapshot.data[1]);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          return CircularProgressIndicator();
        },
      ),
      appBar: widget.appBar,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildImagePicker(),
      ),
    );
  }

  List<Widget> _buildImagePicker() {
    List<Widget> widgets = [];

    widget.settings.imagePickerSource.forEach((imageSource) {
      widgets.add(
        FloatingActionButton(
          onPressed: () async {
            var results = await widget.imagePicker.pickImage(imageSource);
            Navigator.push(context, MaterialPageRoute(
              builder: (BuildContext context) {
                return RoutePredictionsPage(results: results);
              },
            ));
          },
          tooltip: IMAGE_SOURCES[imageSource]["tooltip"],
          child: Icon(IMAGE_SOURCES[imageSource]["icon"]),
          heroTag: IMAGE_SOURCES[imageSource]["heroTag"],
        )
      );

      if (imageSource != widget.settings.imagePickerSource.last) {
        widgets.add(
          SizedBox(height: 16.0)
        );
      }
    });

    return widgets;
  }

  Widget _buildLogbookGrid(Map entries, Map images) {
    List<Widget> widgets = [];

    (_sortEntriesByLogDate(entries)).forEach((id, fields) {
      // Left side - entry description.
      widgets.add(
          Container(
              height: columnHeight,
              width: columnWidth,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              color: Colors.grey[800],
              child: Column(
                children: <Widget>[
                  Text(fields["grade"]),
                  Text(fields["status"]),
                  Text(fields["created_at"]),
                ],
              )
          )
      );

      // Right side - image.
      var imageFields = images["route_images"][fields["route_id"].toString()];
      var imageWidget = (imageFields != null) ?
        Image.memory(base64.decode(imageFields["b64_image"])) :
        Text("No image '$id'");
      widgets.add(
          Container(
            height: columnHeight,
            width: columnWidth,
            color: Colors.white,
            alignment: Alignment.center,
            child: imageWidget,
          )
      );
    });

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: widgets,
    );
  }

  Future<Map> _fetchRouteImages(Future<Map> entries) async {
    var routeIds = [];
    (await entries).forEach((id, fields) {
      routeIds.add(fields["route_id"]);
    });

    return widget.api.fetchRouteImages(routeIds);
  }

  LinkedHashMap _sortEntriesByLogDate(Map entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort((k1, k2) => entries[k1]["created_at"].compareTo(entries[k2]["created_at"]));

    return LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => entries[k]);
  }
}
