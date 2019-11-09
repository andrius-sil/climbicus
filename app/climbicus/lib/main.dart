import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: HomeScreen(),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Climbicus v0.000001'),
      ),
      body: Center(
        child: ImagePickerScreen(),
      ),
    );
  }

}

class ImagePickerScreen extends StatefulWidget {
  @override
  ImagePickerState createState() => ImagePickerState();
}

class ImagePickerState extends State<ImagePickerScreen> {
  File _image;

  Future getImage(ImageSource imageSource) async {
    var image = await ImagePicker.pickImage(
        source: imageSource,
        maxHeight: 150,
        maxWidth: 150,
        imageQuality: 90,
    );

    setState(() {
      _image = image;
      print("Photo size: ${_image.lengthSync()} bytes");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _image == null
            ? Text('No image selected')
            : Image.file(_image)
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () => getImage(ImageSource.gallery),
            tooltip: 'Pick image (gallery)',
            child: Icon(Icons.add_photo_alternate),
          ),
          SizedBox(
            height: 16.0,
          ),
          FloatingActionButton(
            onPressed: () => getImage(ImageSource.camera),
            tooltip: 'Pick image (camera)',
            child: Icon(Icons.add_a_photo),
          ),
        ],
      ),
    );
  }
}
