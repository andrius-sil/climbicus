import 'package:climbicus/json/route.dart' as jsonmdl;
import 'package:climbicus/models/fetch_model.dart';
import 'package:climbicus/utils/api.dart';

class RoutesModel extends FetchModel {
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

  @override
  Future<Map> getEntries() => routes;

  @override
  List<String> displayAttrs(entry) {
    return [entry.grade, entry.createdAt];
  }

  @override
  int routeId(entryId, entry) => entryId;
}
