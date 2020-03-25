import 'dart:convert';
import 'dart:io';

import 'package:climbicus/blocs/route_images_bloc.dart';
import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/ui/route_match.dart';
import 'package:climbicus/utils/api.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'add_route.dart';

class RoutePredictionsPage extends StatefulWidget {
  final ApiProvider api = ApiProvider();
  final Settings settings = Settings();
  final File image;

  RoutePredictionsPage({this.image});

  @override
  State<StatefulWidget> createState() => _RoutePredictionsPageState();
}

class _RoutePredictionsPageState extends State<RoutePredictionsPage> {
  Image _takenImage;
  ImagePickerData _imgPickerData;

  RouteImagesBloc _routeImagesBloc;
  RoutePredictionBloc _routePredictionBloc;

  @override
  void initState() {
    super.initState();

    _routeImagesBloc = BlocProvider.of<RouteImagesBloc>(context);
    _routePredictionBloc = BlocProvider.of<RoutePredictionBloc>(context);
    _routePredictionBloc.add(FetchRoutePrediction(
        image: widget.image,
        displayPredictionsNum: widget.settings.displayPredictionsNum,
    ));

    _takenImage = Image.file(widget.image);
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
                child: BlocBuilder<RoutePredictionBloc, RoutePredictionState>(
                  builder: (context, state) {
                    if (state is RoutePredictionLoadedWithImages) {
                      return _buildPredictionsGrid(context, state.imgPickerData, withImages: true);
                    } else if (state is RoutePredictionLoaded) {
                      return _buildPredictionsGrid(context, state.imgPickerData, withImages: false);
                    } else if (state is RoutePredictionError) {
                      return ErrorWidget.builder(state.errorDetails);
                    }

                    return CircularProgressIndicator();
                  },
                ),
              ),
              BlocBuilder<RoutePredictionBloc, RoutePredictionState>(
                builder: (context, state) {
                  if (state is RoutePredictionLoaded) {
                    _imgPickerData = state.imgPickerData;
                  } else {
                    _imgPickerData = null;
                  }
                  return RaisedButton(
                    child: Text('None of the above'),
                    onPressed: _imgPickerData == null ? null : noMatch,
                  );
                }
              ),
            ]),
          ),
        ),
    );
  }

  Future<void> noMatch() async {
    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return AddRoutePage(imgPickerData: _imgPickerData);
      },
    ));
  }

  Widget _buildPredictionsGrid(BuildContext context, ImagePickerData imgPickerData, {bool withImages: true}) {
    List<Widget> widgets = [];

    for (var i = 0; i < widget.settings.displayPredictionsNum; i++) {
      var fields = imgPickerData.predictions[i];
      var routeId = fields.routeId;
      var grade = fields.grade;

      // Left side - image.
      var imageFields = _routeImagesBloc.images[routeId];
      var imageWidget;
      if (!withImages) {
        imageWidget = Container(width: 0, height: 0);
      } else if (imageFields != null) {
        imageWidget = Image.memory(base64.decode(imageFields.b64Image));
      } else {
        imageWidget = Image.asset("images/no_image.png");
      }
      widgets.add(_buildRouteSelectWrapper(
        Container(
          color: Colors.grey[800],
          alignment: Alignment.center,
          child: imageWidget,
        ),
        routeId,
        imageWidget,
        grade,
        imgPickerData.routeImage.routeImageId,
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
            )
        ),
        routeId,
        imageWidget,
        grade,
        imgPickerData.routeImage.routeImageId,
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
      Widget childWidget, int routeId, Widget imageWidget, String grade, int takenRouteImageId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (BuildContext context) {
            return RouteMatchPage(
              selectedRouteId: routeId,
              selectedImage: imageWidget,
              takenRouteImageId: takenRouteImageId,
              takenImage: _takenImage,
              grade: grade,
            );
          },
        ));
      },
      child: childWidget,
    );
  }
}
