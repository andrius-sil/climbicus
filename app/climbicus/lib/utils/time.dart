
import 'package:intl/intl.dart';

String dateToString(DateTime dt) {
  return DateFormat("dd LLL yyyy").format(dt.toLocal());
}

String dateAndTimeToString(DateTime dt) {
  return DateFormat("yyyy-MM-dd HH:mm").format(dt.toLocal());
}

String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
