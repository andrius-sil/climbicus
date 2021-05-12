import 'dart:io';

import 'package:camera/camera.dart';
import 'package:climbicus/blocs/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class CameraCustom extends StatefulWidget {
  static const routeName = '/camera_custom';

  const CameraCustom();

  @override
  _CameraCustomState createState() => _CameraCustomState();
}

class _CameraCustomState extends State<CameraCustom> {
  final _imagePicker = ImagePicker();

  late List<CameraDescription> _cameras;
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();

    _settingsBloc = BlocProvider.of<SettingsBloc>(context);

    if (!_settingsBloc.seenCameraHelpOverlay) {
      WidgetsBinding.instance!.addPostFrameCallback((_) async {
        _showHelpOverlay();
      });

      _settingsBloc.seenCameraHelpOverlay = true;
    }

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
                textColor: Theme.of(context).buttonColor,
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

    _controller = CameraController(
        _cameras.first,
        ResolutionPreset.max,
        enableAudio: false,
    );
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
      aspectRatio: _controller.value.previewSize!.height / _controller.value.previewSize!.width,
      child: Stack(
        children: <Widget>[
          CameraPreview(_controller),
          Container(
            alignment: Alignment.bottomLeft,
            child: IconButton(
              icon: const Icon(Icons.help),
              iconSize: 32,
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
          icon: const Icon(Icons.panorama_fish_eye),
          iconSize: 64,
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
    var pickedFile = await _imagePicker.getImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    Navigator.pop(context, File(pickedFile.path));
  }

  Future<void> _onTakePictureButtonPressed() async {
    var filepath = await takePicture();
    var imageFile = File(filepath);

    Navigator.pop(context, imageFile);
  }

  Future<String> takePicture() async {
    XFile xfile = await _controller.takePicture();
    return xfile.path;
  }
}
