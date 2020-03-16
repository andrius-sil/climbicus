import 'dart:collection';
import 'dart:convert';

import 'package:climbicus/blocs/route_bloc.dart';
import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/ui/route_predictions.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteViewPage<T extends RouteBloc> extends StatefulWidget {
  final ApiProvider api = ApiProvider();
  final RouteImagePicker imagePicker = RouteImagePicker();
  final Settings settings = Settings();

  RouteViewPage();

  @override
  State<StatefulWidget> createState() => _RouteViewPageState<T>();
}

class _RouteViewPageState<T extends RouteBloc> extends State<RouteViewPage<T>> {
  RouteImagesBloc _routeImagesBloc;
  RouteBloc _routeBloc;

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _routeBloc = BlocProvider.of<T>(context);
    _routeBloc.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<T, RouteState>(
        builder: (context, state) {
          if (state is RouteLoadedWithImages) {
            return _buildLogbookGrid(state.entries, withImages: true);
          } else if (state is RouteLoaded) {
            return _buildLogbookGrid(state.entries, withImages: false);
          } else if (state is RouteError) {
            return ErrorWidget.builder(state.errorDetails);
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
      widgets.add(FloatingActionButton(
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
      ));

      if (imageSource != widget.settings.imagePickerSource.last) {
        widgets.add(SizedBox(height: 16.0));
      }
    });

    return widgets;
  }

  Widget _buildLogbookGrid(Map entries, {bool withImages: true}) {
    List<Widget> widgets = [];

    (_sortEntriesByLogDate(entries)).forEach((entryId, fields) {
      var displayAttrs = _routeBloc.displayAttrs(fields);
      List<Text> textWidgets = [];
      displayAttrs.forEach((String attr) => textWidgets.add(Text(attr)));

      // Left side - entry description.
      widgets.add(Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          color: Colors.grey[800],
          child: Column(
            children: textWidgets,
          )));

      // Right side - image.
      var routeId = _routeBloc.routeId(entryId, fields);
      var imageFields = _routeImagesBloc.images[routeId];
      var imageWidget;
      var imageId;
      if (!withImages) {
        imageWidget = Container(width: 0, height: 0);
      } else if (imageFields != null) {
        imageWidget = Image.memory(base64.decode(imageFields.b64Image));
        imageId = imageFields.routeImageId;
      } else {
        imageWidget = Image.asset("images/no_image.png");
        imageId = "n/a";
      }
      widgets.add(Container(
        color: Colors.grey[700],
        alignment: Alignment.center,
        child: Stack(
          children: <Widget>[
            imageWidget,
            Align(
                alignment: Alignment.bottomLeft,
                child: Text("route_id: $routeId, image_id: $imageId"),
            ),
          ],
        ),
      ));
    });

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: widgets,
    );
  }

  LinkedHashMap _sortEntriesByLogDate(Map entries) {
    var sortedKeys = entries.keys.toList(growable: false)
      ..sort(
          (k1, k2) => entries[k2].createdAt.compareTo(entries[k1].createdAt));

    return LinkedHashMap.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => entries[k]);
  }
}
