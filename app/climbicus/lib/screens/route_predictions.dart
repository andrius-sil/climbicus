import 'dart:io';
import 'dart:math';

import 'package:climbicus/blocs/route_predictions_bloc.dart';
import 'package:climbicus/blocs/settings_bloc.dart';
import 'package:climbicus/screens/route_match.dart';
import 'package:climbicus/widgets/camera_custom.dart';
import 'package:climbicus/widgets/route_image.dart';
import 'package:climbicus/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'add_route.dart';

class RoutePredictionsPage extends StatefulWidget {

  final File image;
  final String routeCategory;

  RoutePredictionsPage({this.image, this.routeCategory});

  @override
  State<StatefulWidget> createState() => _RoutePredictionsPageState();
}

class _RoutePredictionsPageState extends State<RoutePredictionsPage> {
  RouteImageWidget _takenImage;
  ImagePickerData _imgPickerData;

  SettingsBloc _settingsBloc;
  RoutePredictionBloc _routePredictionBloc;

  @override
  void initState() {
    super.initState();

    _settingsBloc = BlocProvider.of<SettingsBloc>(context);
    _routePredictionBloc = BlocProvider.of<RoutePredictionBloc>(context);
    _routePredictionBloc.add(FetchRoutePrediction(
        image: widget.image,
        routeCategory: widget.routeCategory,
    ));

    _takenImage = RouteImageWidget.fromFile(widget.image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Select your route'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    children: [
                      Text("Your route:"),
                      SizedBox(height: COLUMN_PADDING),
                      Container(
                        height: 200.0,
                        width: 200.0,
                        child: _takenImage,
                      ),
                    ],
                  ),
                  SizedBox(height: COLUMN_PADDING * 2),
                  Expanded(child: _buildPredictionsComponent(context)),
                  BlocBuilder<RoutePredictionBloc, RoutePredictionState>(
                    builder: (context, state) {
                      if (state is RoutePredictionLoaded) {
                        _imgPickerData = state.imgPickerData;
                      } else {
                        _imgPickerData = null;
                      }
                      return _buildActionRow(context);
                    }
                  ),
                ],
              )
            );
          }
        ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Column(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () async {
                final imageFile = await Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) {
                    return CameraCustom();
                  },
                ));
                if (imageFile == null) {
                  return;
                }

                Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) {
                    return RoutePredictionsPage(image: imageFile, routeCategory: widget.routeCategory);
                  },
                ));
              },
              iconSize: 48,
            ),
            Text('Retake image'),
          ],
        ),
        Column(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _imgPickerData == null ? null : noMatch,
              iconSize: 48,
            ),
            Text('Add as a new route'),
          ],
        ),
      ],
    );
  }

  Future<void> noMatch() async {
    Navigator.push(context, MaterialPageRoute(
      builder: (BuildContext context) {
        return AddRoutePage(imgPickerData: _imgPickerData, routeCategory: widget.routeCategory);
      },
    ));
  }

  Widget _buildPredictionsComponent(BuildContext context) {
    return Column(
      children: [
        Text("Matches:", style: TextStyle(fontSize: headingSize5or6(context))),
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
      ],
    );
  }

  Widget _buildPredictionsGrid(BuildContext context, ImagePickerData imgPickerData) {
    List<Widget> widgets = [];

    var displayPredictionsNum = min(imgPickerData.predictions.length,
        _settingsBloc.displayPredictionsNum);

    if (displayPredictionsNum == 0) {
      return Text("No matches found!");
    }

    for (var i = 0; i < displayPredictionsNum; i++) {
      var prediction = imgPickerData.predictions[i];
      // Left side - image.
      var routeImage = prediction.routeImage;
      var imageWidget = RouteImageWidget(routeImage);
      widgets.add(_buildRouteSelectWrapper(
        // Recreating image to avoid alignment issues.
        Container(
          color: primaryColorLight,
          alignment: Alignment.center,
          child: imageWidget,
        ),
        prediction.route.id,
        imageWidget,
        imgPickerData.routeImage.id,
      ));

      // Right side - entry description.
      widgets.add(_buildRouteSelectWrapper(
        Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            color: primaryColorLight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text("${prediction.route.grade}"),
              ],
            )
        ),
        prediction.route.id,
        imageWidget,
        imgPickerData.routeImage.id,
      ));
    }

    var scrollController = ScrollController();
    return Scrollbar(
      isAlwaysShown: true,
      controller: scrollController,
      child: GridView.count(
        controller: scrollController,
        primary: false,
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        mainAxisSpacing: 10,
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        children: widgets,
      ),
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
