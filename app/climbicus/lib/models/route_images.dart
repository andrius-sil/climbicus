
import 'dart:async';

import 'package:climbicus/json/route_image.dart';
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

class RouteImagesModel extends ChangeNotifier {
  final ApiProvider api = ApiProvider();

  Map<int, RouteImage> _images = {};
  Future<Map> images = Future.delayed(const Duration(seconds: 60));

  Future<void> fetchData(List<int> routeIds) async {
    images = Future.delayed(const Duration(seconds: 60));

    // Do not fetch already present route images.
    routeIds.removeWhere((id) => _images.containsKey(id));

    try {
      Map<String, dynamic> result = (await api.fetchRouteImages(routeIds))["route_images"];
      var fetchedImages = result.map((id, model) => MapEntry(int.parse(id), RouteImage.fromJson(model)));
      _images.addAll(fetchedImages);
      images = Future.value(_images);
    } catch(e, st) {
      images = Future.error(e, st);
    }

    notifyListeners();
  }
}
