import 'dart:io';

import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/ui/route_match.dart';
import 'package:climbicus/utils/settings.dart';
import 'package:climbicus/widgets/b64image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'add_route.dart';

class RoutePredictionsPage extends StatefulWidget {
  final Settings settings = Settings();
  final File image;

  RoutePredictionsPage({this.image});

  @override
  State<StatefulWidget> createState() => _RoutePredictionsPageState();
}

class _RoutePredictionsPageState extends State<RoutePredictionsPage> {
  Image _takenImage;
  ImagePickerData _imgPickerData;

  RoutePredictionBloc _routePredictionBloc;

  @override
  void initState() {
    super.initState();

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
                    if (state is RoutePredictionLoaded) {
                      return _buildPredictionsGrid(context, state.imgPickerData);
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

  Widget _buildPredictionsGrid(BuildContext context, ImagePickerData imgPickerData) {
    List<Widget> widgets = [];

    for (var i = 0; i < widget.settings.displayPredictionsNum; i++) {
      var fields = imgPickerData.predictions[i];
      var routeId = fields.route.id;
      var grade = fields.route.grade;

      // Left side - image.
      var routeImage = fields.routeImage;
      var imageWidget = B64Image(routeImage);
      widgets.add(_buildRouteSelectWrapper(
        Container(
          color: Colors.grey[800],
          alignment: Alignment.center,
          child: imageWidget,
        ),
        routeId,
        imageWidget,
        imgPickerData.routeImage.id,
      ));

      // Right side - entry description.
      widgets.add(_buildRouteSelectWrapper(
        Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            color: Colors.grey[800],
            child: Column(
              children: <Widget>[
                Text("route_id: ${fields.route.id}"),
                Text("grade: $grade"),
              ],
            )
        ),
        routeId,
        imageWidget,
        imgPickerData.routeImage.id,
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
      Widget childWidget, int routeId, Widget imageWidget, int takenRouteImageId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (BuildContext context) {
            return RouteMatchPage(
              selectedRouteId: routeId,
              selectedImage: imageWidget,
              takenRouteImageId: takenRouteImageId,
              takenImage: _takenImage,
            );
          },
        ));
      },
      child: childWidget,
    );
  }
}
