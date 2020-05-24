
import 'package:path_provider/path_provider.dart';
import 'dart:io';


Future<String> routePicturesDir() async {
  final Directory extDir = await getApplicationDocumentsDirectory();
  final String dirPath = "${extDir.path}/pictures/routes";
  await Directory(dirPath).create(recursive: true);

  return dirPath;
}
