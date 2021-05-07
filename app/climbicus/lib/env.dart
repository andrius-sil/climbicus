
import 'dart:io';

import 'package:device_info/device_info.dart';

enum Environment { dev, stag, prod }

const ENVIRONMENT_NAMES = {
  Environment.dev: "dev",
  Environment.stag: "stag",
  Environment.prod: "prod",
};


class EnvironmentConfig {
  static const ENV = String.fromEnvironment("ENV");
  static const DEV_HOST_IP = String.fromEnvironment("DEV_HOST_IP");

  static void display() {
    print("\tENV: '$ENV'");
    print("\tDEV_HOST_IP: '$DEV_HOST_IP'");
  }
}


Future<bool> _isAndroidEmulator() async {
  var isEmulator = false;

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    isEmulator = !androidInfo.isPhysicalDevice;
  }

  return isEmulator;
}

Future<bool> _isIOSEmulator() async {
  var isEmulator = false;

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    isEmulator = !iosInfo.isPhysicalDevice;
  }

  return isEmulator;
}

const Map<Environment, String> SERVER_URLS = {
  Environment.stag: "http://stag.climbicus.com:5000",
  Environment.prod: "http://prod.climbicus.com:5000",
};

Future<String> getServerUrl(Environment env) async {
  if (env == Environment.dev) {
    if (await _isAndroidEmulator()) {
      return "http://10.0.2.2:5000";
    } else if (await _isIOSEmulator()) {
      return "http://127.0.0.1:5000";
    } else {
      return EnvironmentConfig.DEV_HOST_IP;
    }
  }

  return SERVER_URLS[env]!;
}