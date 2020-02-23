
import 'dart:convert';

import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/models/route_images.dart';
import 'package:climbicus/ui/route_match.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoutePredictionsPage extends StatefulWidget {
  final Settings settings = Settings();
  final ImagePickerResults results;

  RoutePredictionsPage({this.results});

  @override
  State<StatefulWidget> createState() => _RoutePredictionsPageState();
}

class _RoutePredictionsPageState extends State<RoutePredictionsPage> {
  Image takenImage;

  @override
  void initState() {
    super.initState();

    takenImage = Image.file(widget.results.image);

    _fetchData();
  }

  Future<void> _fetchData() async {
    var routeIds = await _routeIds();
    Provider.of<RouteImagesModel>(context, listen: false).fetchData(routeIds);
  }

  @override
  Widget build(BuildContext context) {
    var images = Provider.of<RouteImagesModel>(context).images;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your route'),
      ),
      body: Builder(
        builder: (BuildContext context) =>
          Center(
          child: Column(
            children: <Widget>[
              Text("Your photo:"),
              Container(
                height: 200.0,
                width: 200.0,
                child: takenImage,
              ),
              Text("Our predictions:"),
              Expanded(
                child: FutureBuilder(
                  future: Future.wait([images], eagerError: true),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildPredictionsGrid(context, snapshot.data[0]);
                    } else if (snapshot.hasError) {
                      return ErrorWidget.builder(FlutterErrorDetails(exception: snapshot.error));
                    }

                    return CircularProgressIndicator();
                  },
                ),
              )
            ]),
        ),
      )
    );
  }

  Widget _buildPredictionsGrid(BuildContext context, Map<int, RouteImage> images) {
    List<Widget> widgets = [];

    for (var i = 0; i < widget.settings.displayPredictionsNum; i++) {
      var fields = widget.results.predictions[i];
      var routeId = fields.routeId;
      var grade = fields.grade;

      // Left side - image.
      var imageFields = images[routeId];
      var imageWidget = (imageFields != null) ?
        Image.memory(base64.decode(imageFields.b64Image)) :
        Image.asset("images/no_image.png");
      widgets.add(
          _buildRouteSelectWrapper(
            Container(
              color: Colors.grey[800],
              alignment: Alignment.center,
              child: imageWidget,
            ),
            routeId,
            imageWidget,
            grade,
          )
      );

      // Right side - entry description.
      widgets.add(
        _buildRouteSelectWrapper(
          Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              color: Colors.grey[800],
              child: Column(
                children: <Widget>[
                  Text("route_id: ${fields.routeId}"),
                  Text("grade: $grade"),
                ],
              )
          ),
          routeId,
          imageWidget,
          grade,
        )
      );
    }

    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      children: widgets,
    );
  }

  Widget _buildRouteSelectWrapper(Widget childWidget, int routeId, Image imageWidget, String grade) {
    return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return RouteMatchPage(
                selectedRouteId: routeId,
                selectedImage: imageWidget,
                takenRouteImageId: widget.results.routeImageId,
                takenImage: takenImage,
                grade: grade,
              );
            },
          ));
        },
        child: childWidget,
    );
  }

  Future<List<int>> _routeIds() async {
    List<int> routeIds = List.generate(
        widget.settings.displayPredictionsNum,
            (i) => widget.results.predictions[i].routeId
    );
    return routeIds;
  }

}
