
import 'dart:io';

import 'package:device_info/device_info.dart';

enum Environment { dev, stag, prod }

const ENVIRONMENT_NAMES = {
  Environment.dev: "dev",
  Environment.stag: "stag",
  Environment.prod: "prod",
};

Future<bool> _isPhysicalDevice() async {
  var isPhysicalDevice = true;

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    isPhysicalDevice = androidInfo.isPhysicalDevice;
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    isPhysicalDevice = iosInfo.isPhysicalDevice;
  }

  return isPhysicalDevice;
}

const Map<Environment, String> SERVER_URLS = {
  Environment.stag: "http://stag.climbicus.com:5000",
  Environment.prod: "http://prod.climbicus.com:5000",
};

Future<String> getServerUrl(Environment env) async {
  if (env == Environment.dev) {
    if (!await _isPhysicalDevice()) {
      // If running simulator on dev, then return Android Emulator's IP.
      return "http://10.0.2.2:5000";
    } else {
      const String hostIp = String.fromEnvironment("HOST_IP");
      return hostIp;
    }
  }

  return SERVER_URLS[env];
}