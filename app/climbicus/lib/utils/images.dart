import 'dart:async';
import 'dart:typed_data';

import 'package:climbicus/widgets/route_image.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as i;
import 'dart:ui' as ui;

const JPEG_QUALITY = 75;
const PAINT_STROKE_WIDTH = 4.0;
const PAINT_CIRCLE_RADIUS = 8.0;


int abgrToArgb(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  return (argbColor & 0xFF00FF00) | (b << 16) | r;
}


Future<i.Image?> imageUiToI(ui.Image uiImage) async {
  ByteData? data = await uiImage.toByteData(format: ui.ImageByteFormat.png);
  return i.decodePng(data!.buffer.asUint8List());
}


Future<ui.Image> uiImageFromNetworkPath(String imagePath) async {
  var imageProvider = networkImageFromPath(imagePath);

  Completer<ImageInfo> completer = Completer();
  imageProvider.resolve(ImageConfiguration()).addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    })
  );

  var imageInfo = await completer.future;
  return imageInfo.image;
}


int middleColorByHue(List<int> hexColors) {
  var hsvColors = hexColors.map((c) => HSVColor.fromColor(Color(c)))
      .toList(growable: false)
      ..sort((c1, c2) => c1.hue.compareTo(c2.hue));

  int middle = hsvColors.length ~/ 2;
  return hsvColors[middle].toColor().value;
}


int pixelColorFromImage(i.Image iImage, int x, int y) {
  var pixel32 = iImage.getPixelSafe(x, y);
  var hexColor = abgrToArgb(pixel32);

  return hexColor;
}

