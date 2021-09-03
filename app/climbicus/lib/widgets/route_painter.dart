import 'dart:async';
import 'dart:io';
import 'package:climbicus/utils/images.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as i;
import 'package:path/path.dart' as p;
import 'dart:ui' as ui;

import 'package:climbicus/utils/io.dart';
import 'package:flutter/material.dart';


class PaintedRouteImage {
  final File image;
  final String hexColor;

  PaintedRouteImage(this.image, this.hexColor);
}


class RoutePainterController {
  late double availableHeight;
  late double availableWidth;

  ui.Image? uiBgImage;

  late PathHistory pathHistory;

  int get imageWidth => uiBgImage!.width;
  int get imageHeight => uiBgImage!.height;

  double get _scaleWidth => imageWidth / canvasWidth;
  double get _scaleHeight => imageHeight / canvasHeight;

  late double canvasWidth;
  late double canvasHeight;

  Future<void> initialize(
      double width,
      double height,
      String imageNetworkPath,
  ) async {
    availableHeight = height;
    availableWidth = width;

    uiBgImage = await uiImageFromNetworkPath(imageNetworkPath);

    var imageSize = Size(imageWidth.toDouble(), imageHeight.toDouble());
    var availableSize = Size(availableWidth, availableHeight);
    Size canvasSize = applyBoxFit(BoxFit.contain, imageSize, availableSize).destination;

    canvasWidth = canvasSize.width;
    canvasHeight = canvasSize.height;

    pathHistory = PathHistory(paint: _getPaint(), scaleX: _scaleWidth, scaleY: _scaleHeight);
  }

  Paint _getPaint({double scale = 1.0}) {
    return Paint()
      ..color = Colors.red
      ..strokeWidth = PAINT_STROKE_WIDTH * scale
      ..style = PaintingStyle.stroke;
  }

  Future<PaintedRouteImage> save() async {
    i.Image? iBgImage = await imageUiToI(uiBgImage!);

    List<int> _pointsColors = pathHistory.pointsScaled.map((point) =>
        pixelColorFromImage(iBgImage!, point.dx.toInt(), point.dy.toInt())).toList();
    var overallColor = middleColorByHue(_pointsColors);

    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);

    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, imageWidth.toDouble(), imageHeight.toDouble()),
      image: this.uiBgImage!,
    );

    // canvas.drawPath(_pathHistory.pathScaled, _getPaint(scale: _scaleHeight));
    for (var loc in pathHistory.pointsScaled) {
      canvas.drawCircle(loc, PAINT_CIRCLE_RADIUS * _scaleHeight, _getPaint(scale: _scaleHeight));
    }

    var picture = recorder.endRecording();

    var recordedImage = picture.toImage(imageWidth, imageHeight);
    File savedImageFile = await _saveImage(recordedImage);

    String overallColorHex = overallColor.toRadixString(16);

    print("saved to '${savedImageFile.path}'");
    print("overall color is '$overallColorHex'");

    return PaintedRouteImage(savedImageFile, overallColorHex);
  }

  Future<File> _saveImage(Future<ui.Image> image) async {
    var dirPath = await routePicturesDir();
    var imagePath = p.join(dirPath, "route_image_paint.jpg");
    File imageFile = File(imagePath);

    ui.Image img = await image;
    var decodedImg = await imageUiToI(img);
    imageFile.writeAsBytes(i.encodeJpg(decodedImg!, quality: JPEG_QUALITY));

    return imageFile;
  }
}


class RoutePainter extends StatefulWidget {
  final double availableWidth;
  final double availableHeight;
  final RoutePainterController controller;
  final String imageNetworkPath;

  const RoutePainter({
    required this.availableWidth,
    required this.availableHeight,
    required this.controller,
    required this.imageNetworkPath,
    Key? key,
  }) : super(key: key);

  @override
  _RoutePainterState createState() => _RoutePainterState();
}

class _RoutePainterState extends State<RoutePainter> {
  @override
  void initState() {
    super.initState();

    _initController();
  }

  Future<void> _initController() async {
    await widget.controller.initialize(
      widget.availableWidth,
      widget.availableHeight,
      widget.imageNetworkPath,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.uiBgImage == null) {
      return Center(child: CircularProgressIndicator());
    }

    var customPaint = ClipRect(
      child: CustomPaint(
        painter: ImagePainter(image: widget.controller.uiBgImage!, pathHistory: widget.controller.pathHistory),
        willChange: true,
      ),
    );

    return FittedBox(
      child: SizedBox(
        width: widget.controller.canvasWidth,
        height: widget.controller.canvasHeight,
        child: GestureDetector(
          child: customPaint,
          onTapUp: _onTapUp,
        ),
      ),
    );
  }

  void _onTapUp(TapUpDetails details) {
    widget.controller.pathHistory.add(details.localPosition);

    setState(() {});
  }
}


class PathHistory {
  List<Offset> _points = [];
  List<Offset> _pointsScaled = [];

  var _path = Path();
  var _pathScaled = Path();

  // Used to track whether canvas needs to be redrawn.
  bool wasDrawn = false;

  final Paint paint;

  final double scaleX;
  final double scaleY;

  PathHistory({required this.paint, required this.scaleX, required this.scaleY});

  void add(Offset loc) {
    var locScaled = Offset(loc.dx * scaleX, loc.dy * scaleY);

    _points.add(loc);
    _pointsScaled.add(locScaled);

    if (_points.length == 1) {
      _path.moveTo(loc.dx, loc.dy);
      _pathScaled.moveTo(locScaled.dx, locScaled.dy);
    } else {
      _path.lineTo(loc.dx, loc.dy);
      _pathScaled.lineTo(locScaled.dx, locScaled.dy);
    }

    wasDrawn = false;
  }

  Path get path => _path;
  Path get pathScaled => _pathScaled;

  List<Offset> get points => _points;
  List<Offset> get pointsScaled => _pointsScaled;
}


class ImagePainter extends CustomPainter {
  ui.Image image;
  PathHistory pathHistory;

  ImagePainter({required this.image, required this.pathHistory});

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: image,
    );

    // canvas.drawPath(pathHistory.path, pathHistory.paint);
    for (var loc in pathHistory.points) {
      canvas.drawCircle(loc, PAINT_CIRCLE_RADIUS, pathHistory.paint);
    }

    pathHistory.wasDrawn = true;
  }

  @override
  bool shouldRepaint(covariant ImagePainter oldDelegate) {
    return !pathHistory.wasDrawn;
  }
}
