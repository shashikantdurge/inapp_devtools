import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/subjects.dart';

/// Records log output from `package:logging` for display in [LoggingTool].
///
/// The default implementation listens to [Logger.root] and stores [LogRecord]s
/// in memory.
///
/// See also:
/// * [LoggingTool] — devtools panel that displays recorded entries.
/// * [Logger] — `package:logging` logger used by application code.
abstract class LoggingProfiler {
  static LoggingProfiler? _instance;

  /// The active profiler used to read captured log records.
  ///
  /// Throws if [ensureInitialized] has not been called and [instance] was not
  /// set to a custom implementation.
  static LoggingProfiler get instance {
    if (_instance == null) {
      throw Exception(
        'LoggingProfiler not initialized. Call LoggingProfiler.ensureInitialized() to initialize it.',
      );
    }
    return _instance!;
  }

  /// Replaces the active profiler, disposing the previous one when present.
  static set instance(LoggingProfiler? value) {
    _instance?.dispose();
    _instance = value;
  }

  /// Creates the default in-memory profiler if none exists yet.
  static void ensureInitialized() {
    _instance ??= LoggingProfilerMemoryImpl();
  }

  /// Stream of the full log list; emits whenever a new [LogRecord] is captured.
  Stream<List<LogRecord>> getLoggingDataStream();

  /// Current snapshot of all captured records, or `null` if unavailable.
  List<LogRecord>? getLoggingData();

  /// Removes all captured records.
  void clear();

  /// Releases profiler resources.
  void dispose() {}
}

/// Default [LoggingProfiler] that captures [Logger.root] records in memory.
///
/// Created by [LoggingProfiler.ensureInitialized]. You rarely need to
/// reference this type directly unless replacing [LoggingProfiler.instance].
class LoggingProfilerMemoryImpl implements LoggingProfiler {
  LoggingProfilerMemoryImpl() {
    _subscription = Logger.root.onRecord.listen(_onRecord);
  }

  final BehaviorSubject<List<LogRecord>> _profileDataSubject =
      BehaviorSubject<List<LogRecord>>.seeded([]);

  StreamSubscription<LogRecord>? _subscription;

  void _onRecord(LogRecord record) {
    final updatedData = List<LogRecord>.of(_profileDataSubject.value)
      ..add(record);
    _profileDataSubject.add(updatedData);
  }

  @override
  Stream<List<LogRecord>> getLoggingDataStream() => _profileDataSubject.stream;

  @override
  List<LogRecord>? getLoggingData() => _profileDataSubject.valueOrNull;

  @override
  void clear() {
    _profileDataSubject.add([]);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _profileDataSubject.close();
  }
}
