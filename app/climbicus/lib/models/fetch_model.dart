
import 'package:flutter/widgets.dart';

abstract class FetchModel extends ChangeNotifier {

  Future<void> fetchData();

  List<int> routeIds();

  Future<Map> getEntries();

  List<String> displayAttrs(entry);

  int routeId(entryId, entry);
}
