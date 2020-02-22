import 'dart:collection';
import 'dart:convert';

import 'package:climbicus/json/user_route_log_entry.dart';
import 'package:climbicus/models/route_images.dart';
import 'package:climbicus/models/user_route_log.dart';
import 'package:climbicus/ui/route_predictions.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';



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
  @override
  void initState() {
    super.initState();


    _fetchData();
  }

  Future<void> _fetchData() async {
    await Provider.of<UserRouteLogModel>(context, listen: false).fetchData();

    var routeIds = Provider.of<UserRouteLogModel>(context, listen: false).routeIds();
    Provider.of<RouteImagesModel>(context, listen: false).fetchData(routeIds);
  }

  @override
  Widget build(BuildContext context) {
    var entries = Provider.of<UserRouteLogModel>(context).entries;
    var images = Provider.of<RouteImagesModel>(context).images;

    return Scaffold(
      appBar: widget.appBar,
      body: FutureBuilder(
        future: Future.wait([entries, images], eagerError: true),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildLogbookGrid(snapshot.data[0], snapshot.data[1]);
          } else if (snapshot.hasError) {
            return ErrorWidget.builder(FlutterErrorDetails(exception: snapshot.error));
          }

          return CircularProgressIndicator();
        },
      ),
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
            if (results == null) {
              return;
            }

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

  Widget _buildLogbookGrid(Map<String, UserRouteLogEntry> entries, Map images) {
    List<Widget> widgets = [];

    (_sortEntriesByLogDate(entries)).forEach((id, fields) {
      // Left side - entry description.
      widgets.add(
          Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              color: Colors.grey[800],
              child: Column(
                children: <Widget>[
                  Text(fields.grade),
                  Text(fields.status),
                  Text(fields.createdAt),
                ],
              )
          )
      );

      // Right side - image.
      var imageFields = images[fields.routeId.toString()];
      var imageWidget = (imageFields != null) ?
        Image.memory(base64.decode(imageFields["b64_image"])) :
        Image.asset("images/no_image.png");
      widgets.add(
          Container(
            color: Colors.grey[700],
            alignment: Alignment.center,
            child: imageWidget,
          )
      );
    });

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: widgets,
    );
  }

  LinkedHashMap<String, UserRouteLogEntry> _sortEntriesByLogDate(Map<String, UserRouteLogEntry> entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort((k1, k2) => entries[k2].createdAt.compareTo(entries[k1].createdAt));

    return LinkedHashMap.fromIterable(sortedKeys, key: (k) => k, value: (k) => entries[k]);
  }
}
