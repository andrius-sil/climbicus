import 'dart:io';

import 'package:climbicus/blocs/settings_bloc.dart';
import 'package:climbicus/models/route_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image/network.dart';
import 'package:get_it/get_it.dart';

class RouteImageWidget extends StatefulWidget {
  // Determines how to display scaled image.
  static const defaultBoxFit = BoxFit.cover;

  final RouteImage? routeImage;
  final File? imageFile;

  String? imagePath;
  BoxFit boxFit = defaultBoxFit;

  RouteImageWidget(this.routeImage, {thumbnail: false}) :
    imageFile = null,
    imagePath = thumbnail ? routeImage!.thumbnailPath : routeImage!.path;
  RouteImageWidget.fromFile(this.imageFile) :
    routeImage = null,
    imagePath = null;
  RouteImageWidget.fromPath(this.imagePath, {boxFit = defaultBoxFit}) :
    routeImage = null,
    imageFile = null,
    boxFit = boxFit;

  @override
  RouteImageWidgetState createState() => RouteImageWidgetState();

  static final FetchStrategy fetchStrategy = const FetchStrategyBuilder(
    transientHttpStatusCodePredicate: _transientHttpStatusCodePredicate,
  ).build();

  static bool _transientHttpStatusCodePredicate(int statusCode) {
    return _transientHttpStatusCodes.contains(statusCode);
  }

  static const List<int> _transientHttpStatusCodes = <int>[
    0,   // Network error
    403, // Forbidden (returned by CloudFront if image hasn't been uploaded yet)
    408, // Request timeout
    500, // Internal server error
    502, // Bad gateway
    503, // Service unavailable
    504 // Gateway timeout
  ];
}

class RouteImageWidgetState extends State<RouteImageWidget> {
  final getIt = GetIt.instance;

  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();

    _settingsBloc = BlocProvider.of<SettingsBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    var imageWidget;
    if (widget.imageFile != null) {
      imageWidget = Image.file(widget.imageFile!, fit: widget.boxFit);
    } else if (widget.imagePath != null) {
      imageWidget = Image(
        image: NetworkImageWithRetry(widget.imagePath!, fetchStrategy: RouteImageWidget.fetchStrategy),
        fit: widget.boxFit,
      );
    } else {
      imageWidget = Image.asset("images/no_image.png");
    }
    var scaledImageWidget = ScaledImage(imageWidget);

    if (!_settingsBloc.showImageIds) {
      return scaledImageWidget;
    }

    int? routeId = 0;
    var imageId = 0;
    if (widget.routeImage != null) {
      routeId = widget.routeImage!.routeId;
      imageId = widget.routeImage!.id;
    }
    return Stack(
      children: <Widget>[
        scaledImageWidget,
        Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            "route_id: $routeId\nimage_id: $imageId",
            style: TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }
}


class ScaledImage extends StatelessWidget {
  final Image image;

  ScaledImage(this.image);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      child: image,
      aspectRatio: 1,
    );
  }
}


ImageProvider networkImageFromPath(String imagePath) {
  return NetworkImageWithRetry(
    imagePath,
    fetchStrategy: RouteImageWidget.fetchStrategy,
  );
}
