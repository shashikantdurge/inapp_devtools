import 'package:intl/intl.dart';

String formatLocalTime(DateTime time) {
  return DateFormat('H:mm:ss.SSS').format(time.toLocal());
}
