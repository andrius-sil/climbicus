import 'package:climbicus/json/user_route_log_entry.dart';
import 'package:climbicus/utils/api.dart';

import 'fetch_model.dart';

class UserRouteLogModel extends FetchModel {
  final ApiProvider api = ApiProvider();

  Map<int, UserRouteLogEntry> _entries = {};
  Future<Map> entries = Future.delayed(const Duration(seconds: 60));

  Future<void> fetchData() async {
    entries = Future.delayed(const Duration(seconds: 60));

    try {
      _entries = (await api.fetchLogbook()).map((id, model) =>
          MapEntry(int.parse(id), UserRouteLogEntry.fromJson(model)));
      entries = Future.value(_entries);
    } catch (e, st) {
      entries = Future.error(e, st);
    }

    notifyListeners();
  }

  Future<void> add(int routeId, String grade, String status) async {
    var results = await api.logbookAdd(routeId, status);

    var newEntry = UserRouteLogEntry(
      routeId,
      grade,
      status,
      results["created_at"],
    );
    _entries[results["id"]] = newEntry;

    notifyListeners();
  }

  List<int> routeIds() {
    return _entries.values.map((entry) => entry.routeId).toList();
  }

  @override
  Future<Map> getEntries() => entries;

  @override
  List<String> displayAttrs(entry) {
    return [entry.grade, entry.status, entry.createdAt];
  }

  @override
  int routeId(entryId, entry) => entry.routeId;
}
