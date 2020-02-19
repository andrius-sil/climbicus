
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

class RouteImagesModel extends ChangeNotifier {
  final ApiProvider api = ApiProvider();

  Map _images = {};

  Future<Map> images = Future.delayed(const Duration(seconds: 60));

  Future<void> fetchData(Future<List> routeIds) async {
    images = Future.delayed(const Duration(seconds: 60));

    api.fetchRouteImages(await routeIds).then((result) {
      _images.addAll(result["route_images"]);
      images = Future.value(_images);

      notifyListeners();
    });
  }
}
