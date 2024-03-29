import 'dart:async';
import 'dart:io';
import 'package:climbicus/utils/images.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as i;
import 'package:path/path.dart' as p;
import 'dart:ui' as ui;

import 'package:climbicus/utils/io.dart';
import 'package:flutter/material.dart';


class RoutePainter extends StatefulWidget {
  final double height;
  final String imageNetworkPath;

  const RoutePainter({
    required this.height,
    required this.imageNetworkPath,
    Key? key,
  }) : super(key: key);

  @override
  _RoutePainterState createState() => _RoutePainterState();
}

class _RoutePainterState extends State<RoutePainter> {
  ui.Image? uiBgImage;
  i.Image? iBgImage;

  late PathHistory _pathHistory;

  @override
  void initState() {
    super.initState();

    _getImage();
  }

  Future<void> _getImage() async {
    uiBgImage = await uiImageFromNetworkPath(widget.imageNetworkPath);
    iBgImage = await imageUiToI(uiBgImage!);

    _pathHistory = PathHistory(paint: _getPaint(), scaleX: _scaleWidth, scaleY: _scaleHeight);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (this.uiBgImage == null) {
      return Center(child: CircularProgressIndicator());
    }

    var customPaint = ClipRect(
      child: CustomPaint(
        painter: ImagePainter(image: uiBgImage!, pathHistory: _pathHistory),
        willChange: true,
      ),
    );

    var paintingImage = FittedBox(
      child: SizedBox(
        height: _canvasHeight,
        width: _canvasWidth,
        child: GestureDetector(
          child: customPaint,
          onTapUp: _onTapUp,
        ),
      ),
    );

    return Column(
      children: [
        Expanded(child: paintingImage),
        ElevatedButton(
          child: Text("save"),
          onPressed: _onSave,
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    List<int> _pointsColors = _pathHistory.pointsScaled.map((point) =>
      pixelColorFromImage(iBgImage!, point.dx.toInt(), point.dy.toInt())).toList();
    var overallColor = middleColorByHue(_pointsColors);

    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);

    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, _imageWidth.toDouble(), _imageHeight.toDouble()),
      image: this.uiBgImage!,
    );

    // canvas.drawPath(_pathHistory.pathScaled, _getPaint(scale: _scaleHeight));
    for (var loc in _pathHistory.pointsScaled) {
      canvas.drawCircle(loc, PAINT_CIRCLE_RADIUS * _scaleHeight, _getPaint(scale: _scaleHeight));
    }

    var picture = recorder.endRecording();

    var recordedImage = picture.toImage(_imageWidth, _imageHeight);
    String savedImagePath = await _saveImage(recordedImage);

    // TODO: wrap in a results class
    print("saved to '$savedImagePath'");
    print("overall color is '${overallColor.toRadixString(16)}");
  }

  Future<String> _saveImage(Future<ui.Image> image) async {
    var dirPath = await routePicturesDir();
    var imagePath = p.join(dirPath, "route_image_paint.jpg");
    File imageFile = File(imagePath);

    ui.Image img = await image;
    var decodedImg = await imageUiToI(img);
    imageFile.writeAsBytes(i.encodeJpg(decodedImg!, quality: JPEG_QUALITY));

    return imagePath;
  }

  void _onTapUp(TapUpDetails details) {
    _pathHistory.add(details.localPosition);

    setState(() {});
  }

  Paint _getPaint({double scale = 1.0}) {
    return Paint()
      ..color = Colors.red
      ..strokeWidth = PAINT_STROKE_WIDTH * scale
      ..style = PaintingStyle.stroke;
  }

  double get _aspectRatio => uiBgImage!.width / uiBgImage!.height;

  double get _canvasHeight => widget.height;
  double get _canvasWidth => widget.height * _aspectRatio;

  int get _imageHeight => uiBgImage!.height;
  int get _imageWidth => uiBgImage!.width;

  double get _scaleHeight => _imageHeight / _canvasHeight;
  double get _scaleWidth => _imageWidth / _canvasWidth;
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
