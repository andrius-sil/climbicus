
import 'package:flutter/widgets.dart';

abstract class FetchModel extends ChangeNotifier {

  Future<void> fetchData();

  List<int> routeIds();

  Future<Map> getEntries();
}
