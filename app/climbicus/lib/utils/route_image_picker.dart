
import 'package:image_picker/image_picker.dart';

import 'api.dart';


class ImagePickerResults {
  final image;
  final predictions;

  const ImagePickerResults(this.image, this.predictions);
}


class RouteImagePicker {
  final Api api;

  RouteImagePicker({this.api});

  Future<ImagePickerResults> getGalleryImage() async {
    return _getImage(ImageSource.gallery);
  }

  Future<ImagePickerResults> getCameraImage() async {
    return _getImage(ImageSource.camera);
  }

  Future<ImagePickerResults> _getImage(ImageSource imageSource) async {
    var image = await ImagePicker.pickImage(
      source: imageSource,
      maxWidth: 1028,
      imageQuality: 76,
    );

    if (image == null) {
      return null;
    }

    print("Photo size: ${image.lengthSync()} bytes");

    var predictions = api.uploadRouteImage(image);
    return new ImagePickerResults(image, predictions);
  }

}
