
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';


const Map<String, List<ImageSource>> IMAGE_PICKERS = {
  "gallery": [ImageSource.gallery],
  "camera": [ImageSource.camera],
  "both": [ImageSource.gallery, ImageSource.camera]
};


class SettingsState {
  final String imagePicker;
  final int displayPredictionsNum;
  final int gymId;
  final PackageInfo packageInfo;

  SettingsState({
    @required this.imagePicker,
    @required this.displayPredictionsNum,
    @required this.gymId,
    @required this.packageInfo,
  });

  List<ImageSource> get imagePickerSources => IMAGE_PICKERS[imagePicker];
}

class SettingsUninitialized extends SettingsState {}

abstract class SettingsEvent {
  const SettingsEvent();
}

class InitializedSettings extends SettingsEvent {}

class ImagePickerChanged extends SettingsEvent {
  final String imagePicker;
  const ImagePickerChanged({@required this.imagePicker});
}

class GymChanged extends SettingsEvent {
  final int gymId;
  const GymChanged({@required this.gymId});
}


class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  // Initialise settings with default values.
  String _imagePicker = "both";
  int _displayPredictionsNum = 3;
  int _gymId = 1;
  PackageInfo _packageInfo;

  int get gymId => _gymId;

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
    gymId: _gymId,
    packageInfo: _packageInfo,
  );

  @override
  SettingsState get initialState => SettingsUninitialized();

  Future<void> retrieveSettings() async {
    _imagePicker = await retrieveSetting("image_picker", _imagePicker);
    _displayPredictionsNum = int.parse(await retrieveSetting(
        "display_predictions_num", _displayPredictionsNum.toString()));
    _gymId = int.parse(await retrieveSetting("gym_id", _gymId.toString()));

    _packageInfo = await PackageInfo.fromPlatform();

    add(InitializedSettings());
  }

  @override
  Stream<SettingsState> mapEventToState(SettingsEvent event) async* {
    if (event is InitializedSettings) {
      yield createState();
    } else if (event is ImagePickerChanged) {
      _imagePicker = event.imagePicker;
      yield createState();
      storeSetting("image_picker", _imagePicker);
    } else if (event is GymChanged) {
      _gymId = event.gymId;
      yield createState();
      storeSetting("gym_id", _gymId.toString());
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
