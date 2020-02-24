import 'package:climbicus/json/route.dart' as jsonmdl;
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

class RoutesModel extends ChangeNotifier {
  final ApiProvider api = ApiProvider();

  Map<int, jsonmdl.Route> _routes = {};
  Future<Map> routes = Future.delayed(const Duration(seconds: 60));

  Future<void> fetchData() async {
    routes = Future.delayed(const Duration(seconds: 60));

    try {
      Map<String, dynamic> result = (await api.fetchRoutes())["routes"];
      _routes = result.map((id, model) =>
          MapEntry(int.parse(id), jsonmdl.Route.fromJson(model)));
      routes = Future.value(_routes);
    } catch (e, st) {
      routes = Future.error(e, st);
    }

    notifyListeners();
  }

  List<int> routeIds() {
    return _routes.keys.toList();
  }
}
