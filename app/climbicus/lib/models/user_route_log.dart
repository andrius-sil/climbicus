
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

class UserRouteLogModel extends ChangeNotifier {
  final ApiProvider api = ApiProvider();

  Future<Map> _entries = Future.delayed(const Duration(seconds: 60));
  Future<Map> get entries => _entries;

  void fetchData() {
    _entries = api.fetchLogbook();
  }

  Future<void> add(int routeId, String grade, String status) async {
    api.logbookAdd(routeId, status).then((Map results) async {
      Map<String, dynamic> fields = {};
      fields["route_id"] = routeId;
      fields["grade"] = grade;
      fields["status"] = status;
      fields["created_at"] = results["created_at"];
      (await _entries)[results["id"].toString()] = fields;

      notifyListeners();
    });
  }
}
