
import 'dart:async';

import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

class RouteImagesModel extends ChangeNotifier {
  final ApiProvider api = ApiProvider();

  Map _images = {};
  Future<Map> images = Future.delayed(const Duration(seconds: 60));

  Future<void> fetchData(List routeIds) async {
    images = Future.delayed(const Duration(seconds: 60));

    try {
      var result = await api.fetchRouteImages(routeIds);
      _images.addAll(result["route_images"]);
      images = Future.value(_images);
    } catch(e, st) {
      images = Future.error(e, st);
    }

    notifyListeners();
  }
}
