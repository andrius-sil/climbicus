
import 'package:bloc/bloc.dart';
import 'package:climbicus/repositories/api_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';


const PLACEHOLDER_GYM_ID = -1;


class SettingsState {
  final int displayPredictionsNum;
  final int gymId;
  final PackageInfo packageInfo;
  final bool seenCameraHelpOverlay;

  SettingsState({
    @required this.displayPredictionsNum,
    @required this.gymId,
    @required this.packageInfo,
    @required this.seenCameraHelpOverlay,
  });
}

class SettingsUninitialized extends SettingsState {}

abstract class SettingsEvent {
  const SettingsEvent();
}

class InitializedSettings extends SettingsEvent {}

class GymChanged extends SettingsEvent {
  final int gymId;
  const GymChanged({@required this.gymId});
}


class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final getIt = GetIt.instance;

  // Initialise settings with default values.
  String _imagePicker = "both";
  int _displayPredictionsNum = 3;
  int _gymId = PLACEHOLDER_GYM_ID;
  PackageInfo _packageInfo;
  bool _seenCameraHelpOverlay = false;

  int get gymId => _gymId;

  int get displayPredictionsNum => _displayPredictionsNum;
  set displayPredictionsNum(int i) {
    _displayPredictionsNum = i;
    storeSetting("display_predictions_num", _displayPredictionsNum.toString());
  }

  bool get seenCameraHelpOverlay => _seenCameraHelpOverlay;
  set seenCameraHelpOverlay(bool v) {
    _seenCameraHelpOverlay = v;
    storeSetting("seen_camera_help_overlay", _seenCameraHelpOverlay.toString());
  }

  SettingsBloc() : super(SettingsUninitialized()) {
    retrieveSettings();
  }

  SettingsState createState() => SettingsState(
    displayPredictionsNum: _displayPredictionsNum,
    gymId: _gymId,
    packageInfo: _packageInfo,
    seenCameraHelpOverlay: _seenCameraHelpOverlay,
  );

  Future<void> retrieveSettings() async {
    _imagePicker = await retrieveSetting("image_picker", _imagePicker);
    _displayPredictionsNum = int.parse(await retrieveSetting(
        "display_predictions_num", _displayPredictionsNum.toString()));
    _gymId = int.parse(await retrieveSetting("gym_id", _gymId.toString()));

    _packageInfo = await PackageInfo.fromPlatform();

    _seenCameraHelpOverlay = (await retrieveSetting("seen_camera_help_overlay",
      _seenCameraHelpOverlay.toString())) == "true";

    getIt<ApiRepository>().gymId = _gymId;

    add(InitializedSettings());
  }

  @override
  Stream<SettingsState> mapEventToState(SettingsEvent event) async* {
    if (event is InitializedSettings) {
      yield createState();
    } else if (event is GymChanged) {
      _gymId = event.gymId;
      getIt<ApiRepository>().gymId = _gymId;
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
