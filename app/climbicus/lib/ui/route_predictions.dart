import 'dart:convert';

import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/ui/route_match.dart';
import 'package:climbicus/utils/route_image_picker.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'add_route.dart';

class RoutePredictionsPage extends StatefulWidget {
  final Settings settings = Settings();
  final ImagePickerData imgPickerData;

  RoutePredictionsPage({this.imgPickerData});

  @override
  State<StatefulWidget> createState() => _RoutePredictionsPageState();
}

class _RoutePredictionsPageState extends State<RoutePredictionsPage> {
  Image _takenImage;
  RouteImagesBloc _routeImagesBloc;

  @override
  void initState() {
    super.initState();

    _takenImage = Image.file(widget.imgPickerData.image);
    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);

    var routeIds = _routeIds();
    _routeImagesBloc.add(FetchRouteImages(routeIds: routeIds));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Select your route'),
        ),
        body: Builder(
          builder: (BuildContext context) => Center(
            child: Column(children: <Widget>[
              Text("Your photo:"),
              Container(
                height: 200.0,
                width: 200.0,
                child: _takenImage,
              ),
              Text("Our predictions:"),
              Expanded(
                child: BlocBuilder<RouteImagesBloc, RouteImagesState>(
                  builder: (context, state) {
                    if (state is RouteImagesLoaded) {
                      return _buildPredictionsGrid(context, state.images);
                    } else if (state is RouteImagesError) {
                      return ErrorWidget.builder(state.errorDetails);
                    }

                    return CircularProgressIndicator();
                  },
                ),
              ),
              RaisedButton(
                child: Text('None of the above'),
                onPressed: noMatch,
              ),
            ]),
          ),
        ),
    );
  }

  Future<void> noMatch() async {
    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return AddRoutePage(imgPickerData: widget.imgPickerData);
      },
    ));
  }

  Widget _buildPredictionsGrid(
      BuildContext context, Map<int, RouteImage> images) {
    List<Widget> widgets = [];

    for (var i = 0; i < widget.settings.displayPredictionsNum; i++) {
      var fields = widget.imgPickerData.predictions[i];
      var routeId = fields.routeId;
      var grade = fields.grade;

      // Left side - image.
      var imageFields = images[routeId];
      var imageWidget = (imageFields != null)
          ? Image.memory(base64.decode(imageFields.b64Image))
          : Image.asset("images/no_image.png");
      widgets.add(_buildRouteSelectWrapper(
        Container(
          color: Colors.grey[800],
          alignment: Alignment.center,
          child: imageWidget,
        ),
        routeId,
        imageWidget,
        grade,
      ));

      // Right side - entry description.
      widgets.add(_buildRouteSelectWrapper(
        Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            color: Colors.grey[800],
            child: Column(
              children: <Widget>[
                Text("route_id: ${fields.routeId}"),
                Text("grade: $grade"),
              ],
            )),
        routeId,
        imageWidget,
        grade,
      ));
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

  Widget _buildRouteSelectWrapper(
      Widget childWidget, int routeId, Image imageWidget, String grade) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (BuildContext context) {
            return RouteMatchPage(
              selectedRouteId: routeId,
              selectedImage: imageWidget,
              takenRouteImageId: widget.imgPickerData.routeImage.routeImageId,
              takenImage: _takenImage,
              grade: grade,
            );
          },
        ));
      },
      child: childWidget,
    );
  }

  List<int> _routeIds() {
    List<int> routeIds = List.generate(widget.settings.displayPredictionsNum,
        (i) => widget.imgPickerData.predictions[i].routeId);
    return routeIds;
  }
}
