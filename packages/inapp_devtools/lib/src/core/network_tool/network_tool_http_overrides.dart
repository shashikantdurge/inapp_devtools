import 'dart:io';

import 'package:inapp_devtools/src/core/network_tool/http_profiler.dart';
import 'package:inapp_devtools/src/core/network_tool/network_tool_http_client.dart';

class NetworkToolHttpOverrides extends HttpOverrides {
  static final HttpProfiler httpProfiler = HttpProfilerMemoryImpl();
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final innerHttpClient = super.createHttpClient(context);
    return NetworkToolHttpClient(innerHttpClient);
  }
}
