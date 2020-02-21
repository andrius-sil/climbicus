
import 'package:climbicus/utils/api.dart';
import 'package:flutter/widgets.dart';

class UserRouteLogModel extends ChangeNotifier {
  final ApiProvider api = ApiProvider();

  Map _entries = {};
  Future<Map> entries = Future.delayed(const Duration(seconds: 60));

  Future<void> fetchData() async {
    entries = Future.delayed(const Duration(seconds: 60));

    try {
      _entries = await api.fetchLogbook();
      entries = Future.value(_entries);
    } catch(e, st) {
      entries = Future.error(e, st);
    }

    notifyListeners();
  }

  Future<void> add(int routeId, String grade, String status) async {
    var results = await api.logbookAdd(routeId, status);

    Map<String, dynamic> fields = {};
    fields["route_id"] = routeId;
    fields["grade"] = grade;
    fields["status"] = status;
    fields["created_at"] = results["created_at"];
    _entries[results["id"].toString()] = fields;

    notifyListeners();
  }

  List routeIds() {
    var routeIds = [];
    _entries.forEach((id, fields) {
      routeIds.add(fields["route_id"]);
    });

    return routeIds;
  }
}
