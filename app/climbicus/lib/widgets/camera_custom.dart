import 'dart:io';

import 'package:camera/camera.dart';
import 'package:climbicus/utils/io.dart';
import 'package:climbicus/utils/time.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraCustom extends StatefulWidget {
  const CameraCustom();

  @override
  _CameraCustomState createState() => _CameraCustomState();
}

class _CameraCustomState extends State<CameraCustom> {
  List<CameraDescription> _cameras;
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    // TODO: show first time only
//    WidgetsBinding.instance.addPostFrameCallback((_) async {
//      _showHelpOverlay();
//    });

    initCamera();
  }

  void _showHelpOverlay() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black12.withOpacity(0.6),
      barrierDismissible: false,
      barrierLabel: "info",
      transitionDuration: Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) {
        return Container(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: Image.network("http://dev-cdn.climbicus.com/assets/overlay_white.png"),
                  ),
                ),
              ),
              FlatButton(
                textColor: Colors.blue,
                child: Text(
                  "OK, got it!",
                  style: TextStyle(fontSize: 24),
                ),
                onPressed: () { Navigator.of(context).pop(); },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> initCamera() async {
    _cameras = await availableCameras();

    _controller = CameraController(_cameras.first, ResolutionPreset.max);
    _initializeControllerFuture = _controller.initialize();

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(1.0),
                    child: Center(
                      child: _buildCameraPreview(),
                    )
                  ),
                ),
                _buildCaptureRow(),
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildCameraPreview() {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        children: <Widget>[
          CameraPreview(_controller),
          Container(
            alignment: Alignment.bottomLeft,
            child: IconButton(
              icon: const Icon(Icons.info),
              onPressed: _showHelpOverlay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.cancel),
          iconSize: 32,
          tooltip: "go back",
          onPressed: () { Navigator.pop(context); },
        ),
        IconButton(
          icon: const Icon(Icons.camera_alt),
          iconSize: 48,
          tooltip: "take a picture",
          onPressed: _onTakePictureButtonPressed,
        ),
        IconButton(
          icon: const Icon(Icons.add_photo_alternate),
          iconSize: 32,
          tooltip: "select picture from files",
          onPressed: _onPickPictureButtonPressed,
        ),
      ],
    );
  }

  Future<void> _onPickPictureButtonPressed() async {
    var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) {
      return;
    }

    Navigator.pop(context, imageFile);
  }

  Future<void> _onTakePictureButtonPressed() async {
    var filepath = await takePicture();
    var imageFile = File(filepath);

    Navigator.pop(context, imageFile);
  }

  Future<String> takePicture() async {
    var dirPath = await routePicturesDir();
    final String filePath = "$dirPath/${timestamp()}.jpg";

    await _controller.takePicture(filePath);
    return filePath;
  }
}
