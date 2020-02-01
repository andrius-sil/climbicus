import 'dart:io';

import 'package:climbicus/utils/api.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerPage extends StatefulWidget {
  final Api api;

  ImagePickerPage({this.api});

  @override
  ImagePickerState createState() => ImagePickerState();
}

class ImagePickerState extends State<ImagePickerPage> {
  File _image;
  Future<String> _predictedClassId;

  Future getImage(ImageSource imageSource) async {
    var image = await ImagePicker.pickImage(
      source: imageSource,
      maxWidth: 1028,
      imageQuality: 76,
    );

    setState(() {
      _image = image;
      print("Photo size: ${_image.lengthSync()} bytes");

      _predictedClassId = widget.api.uploadRouteImage(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    var imageWidget = _image == null ? Text('No image selected') : Image.file(_image);
    return Scaffold(
      body: Center(
        child: Column(
            children: <Widget>[
              FutureBuilder<String>(
                future: _predictedClassId,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data);
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }

                  return CircularProgressIndicator();
                },
              ),
              imageWidget,
            ]),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () => getImage(ImageSource.gallery),
            tooltip: 'Pick image (gallery)',
            child: Icon(Icons.add_photo_alternate),
            heroTag: "btnGallery",
          ),
          SizedBox(
            height: 16.0,
          ),
          FloatingActionButton(
            onPressed: () => getImage(ImageSource.camera),
            tooltip: 'Pick image (camera)',
            child: Icon(Icons.add_a_photo),
            heroTag: "btnCamera",
          ),
        ],
      ),
    );
  }

}
