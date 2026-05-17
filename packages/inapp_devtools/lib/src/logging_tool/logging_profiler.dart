import 'package:logging/logging.dart';
import 'package:rxdart/subjects.dart';

class LoggingProfiler {
  static LoggingProfiler? _instance;

  static LoggingProfiler get instance {
    _instance ??= LoggingProfiler._();
    return _instance!;
  }

  static void ensureInitialized() {
    _instance ??= LoggingProfiler._();
  }

  LoggingProfiler._() {
    Logger.root.onRecord.listen((record) {
      final updatedData = _profileDataSubject.value..add(record);
      _profileDataSubject.add(updatedData);
    });
  }

  final _profileDataSubject = BehaviorSubject<List<LogRecord>>.seeded([]);

  Stream<List<LogRecord>> getLoggingDataStream() => _profileDataSubject.stream;

  List<LogRecord>? getLoggingData() => _profileDataSubject.valueOrNull;

  void clear() {
    _profileDataSubject.add([]);
  }

  void dispose() {
    _profileDataSubject.close();
    _instance = null;
  }
}
