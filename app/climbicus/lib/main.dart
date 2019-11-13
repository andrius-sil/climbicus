import 'dart:io';

import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  static const BASE_URL = "http://3.11.0.15:5000";

  File _image;
  Future<String> _predictedClassId;

  Future<String> uploadRouteImage(File image) async {
    var uri = Uri.parse("$BASE_URL/predict");
    var request = new http.MultipartRequest("POST", uri);

    var stream = new http.ByteStream(DelegatingStream.typed(image.openRead()));
    var length = await image.length();
    var multipartFile = new http.MultipartFile(
      'image',
      stream,
      length,
      filename: basename(image.path)
    );
    request.files.add(multipartFile);

    var response = await request.send();
    if (response.statusCode == 200) {
      var value = response.stream.bytesToString();
      return value;
    } else {
      throw Exception("request failed with ${response.statusCode}");
    }
  }

  Future getImage(ImageSource imageSource) async {
    var image = await ImagePicker.pickImage(
        source: imageSource,
        maxWidth: 1028,
        imageQuality: 76,
    );

    setState(() {
      _image = image;
      print("Photo size: ${_image.lengthSync()} bytes");

      _predictedClassId = uploadRouteImage(image);
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
