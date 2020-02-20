
import 'dart:convert';

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
  int takenImageId;

  @override
  void initState() {
    super.initState();

    takenImage = Image.file(widget.results.image);
    _setTakenImageId();

    Provider.of<RouteImagesModel>(context, listen: false).fetchData(
      _routeIds(),
    );
  }

  Future<void> _setTakenImageId() async {
    takenImageId = (await widget.results.predictions)["route_image_id"];
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
                  future: Future.wait([widget.results.predictions, images]),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildPredictionsGrid(context, snapshot.data[0], snapshot.data[1]);
                    } else if (snapshot.hasError) {
                      debugPrint("${snapshot.error}");
                      return Text("${snapshot.error}");
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

  Widget _buildPredictionsGrid(BuildContext context, Map predictions, Map images) {
    List<Widget> widgets = [];

    for (var i = 0; i < widget.settings.displayPredictionsNum; i++) {
      var fields = predictions["sorted_route_predictions"][i];
      var routeId = fields["route_id"];
      var grade = fields["grade"];

      // Left side - image.
      var imageFields = images[routeId.toString()];
      var imageWidget = (imageFields != null) ?
        Image.memory(base64.decode(imageFields["b64_image"])) :
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
                  Text("route_id: ${fields["route_id"]}"),
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
                takenRouteImageId: takenImageId,
                takenImage: takenImage,
                grade: grade,
              );
            },
          ));
        },
        child: childWidget,
    );
  }

  Future<List> _routeIds() async {
    var p = await widget.results.predictions;
    var routeIds = List.generate(
        widget.settings.displayPredictionsNum,
            (i) => p["sorted_route_predictions"][i]["route_id"]
    );
    return routeIds;
  }

}
