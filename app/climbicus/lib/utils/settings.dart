
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  // Singleton factory.
  static final Settings _settings = Settings._internal();
  factory Settings() => _settings;
  Settings._internal() {
    retrieveSetting("server", _server).then((String val) => _server = val);
    retrieveSetting("image_picker", _imagePicker).then((String val) => _imagePicker = val);
  }

  static const Map<String, String> serverUrls = {
    "dev": "http://3.11.0.15:5000",
    "prod": "http://3.11.49.99:5000",
  };

  static const Map<String, List<ImageSource>> imagePickers = {
    "gallery": [ImageSource.gallery],
    "camera": [ImageSource.camera],
    "both": [ImageSource.camera, ImageSource.gallery]
  };


  String _server = "dev";
  String get server => _server;
  String get serverUrl => serverUrls[_server];
  set server(String s) {
    _server = s;
    storeSetting("server", s);
  }

  String _imagePicker = "both";
  String get imagePicker => _imagePicker;
  List<ImageSource> get imagePickerSource => imagePickers[_imagePicker];
  set imagePicker(String p) {
    _imagePicker = p;
    storeSetting("image_picker", p);
  }

  Future<void> storeSetting(String settingName, String val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(settingName, val);
  }

  Future<String> retrieveSetting (String settingName, String defaultVal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(settingName)) {
      return prefs.getString(settingName);
    }

    return defaultVal;
  }
}
