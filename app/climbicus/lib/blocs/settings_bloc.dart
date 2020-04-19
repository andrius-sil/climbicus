
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';


const Map<String, List<ImageSource>> IMAGE_PICKERS = {
  "gallery": [ImageSource.gallery],
  "camera": [ImageSource.camera],
  "both": [ImageSource.gallery, ImageSource.camera]
};


class SettingsState {
  final String imagePicker;
  final int displayPredictionsNum;

  SettingsState({
    @required this.imagePicker,
    @required this.displayPredictionsNum,
  });

  List<ImageSource> get imagePickerSources => IMAGE_PICKERS[imagePicker];
}

class SettingsUninitialized extends SettingsState {}

abstract class SettingsEvent {
  const SettingsEvent();
}

class InitialisedSettings extends SettingsEvent {}

class ImagePickerChanged extends SettingsEvent {
  final String imagePicker;
  const ImagePickerChanged({@required this.imagePicker});
}


class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  // Initialise settings with default values.
  String _imagePicker = "both";
  int _displayPredictionsNum = 3;

  int get displayPredictionsNum => _displayPredictionsNum;
  set displayPredictionsNum(int i) {
    _displayPredictionsNum = i;
    storeSetting("display_predictions_num", _displayPredictionsNum.toString());
  }

  SettingsBloc() {
    retrieveSettings();
  }

  SettingsState createState() => SettingsState(
    imagePicker: _imagePicker,
    displayPredictionsNum: _displayPredictionsNum,
  );

  @override
  SettingsState get initialState => SettingsUninitialized();

  Future<void> retrieveSettings() async {
    _imagePicker = await retrieveSetting("image_picker", _imagePicker);
    _displayPredictionsNum = int.parse(await retrieveSetting(
        "display_predictions_num", _displayPredictionsNum.toString()));

    add(InitialisedSettings());
  }

  @override
  Stream<SettingsState> mapEventToState(SettingsEvent event) async* {
    if (event is InitialisedSettings) {
      yield createState();
    } else if (event is ImagePickerChanged) {
      _imagePicker = event.imagePicker;
      yield createState();
      storeSetting("image_picker", _imagePicker);
    }
  }

  Future<void> storeSetting(String settingName, String val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(settingName, val);
  }

  Future<String> retrieveSetting(String settingName, String defaultVal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(settingName)) {
      return prefs.getString(settingName);
    }

    return defaultVal;
  }
}
