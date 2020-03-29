
import 'package:intl/intl.dart';

String dateToString(DateTime dt) {
  return DateFormat("yyyy-MM-dd").format(dt.toLocal());
}

String dateAndTimeToString(DateTime dt) {
  return DateFormat("yyyy-MM-dd HH:mm").format(dt.toLocal());
}
