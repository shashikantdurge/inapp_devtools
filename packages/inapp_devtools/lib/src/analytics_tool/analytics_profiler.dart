import 'package:rxdart/subjects.dart';

import 'analytics_profile_data.dart';

abstract class AnalyticsProfiler {
  static AnalyticsProfiler? _instance;

  /// The active profiler used to record and read analytics entries.
  ///
  /// Throws if [ensureInitialized] has not been called and [instance] was not
  /// set to a custom implementation.
  static AnalyticsProfiler get instance {
    if (_instance == null) {
      throw Exception(
        'AnalyticsProfiler not initialized. Call AnalyticsProfiler.ensureInitialized() to initialize it.',
      );
    }
    return _instance!;
  }

  /// Replaces the active profiler, disposing the previous one when present.
  static set instance(AnalyticsProfiler? value) {
    _instance?.dispose();
    _instance = value;
  }

  /// Creates the default in-memory profiler if none exists yet.
  static void ensureInitialized() {
    _instance ??= AnalyticsProfilerMemoryImpl();
  }

  /// Logs a named analytics event with optional [parameters].
  void logEvent(String name, {Map<String, Object?>? parameters});

  /// Logs a screen view with optional [parameters].
  void logScreenView(String screenName, {Map<String, Object?>? parameters});

  /// Sets the current user id.
  void setUserId(String? userId);

  /// Sets a user property identified by [name] to [value].
  void setUserProperty(String name, Object? value);

  /// Records global parameters (for example app state or environment).
  void setGlobalParameters(Map<String, Object?> parameters);

  /// Stream of the full entry list.
  Stream<List<AnalyticsProfileData>> getProfileDataStream();

  /// Current snapshot of all recorded entries.
  List<AnalyticsProfileData>? getProfileData();

  /// Removes all recorded entries.
  void clear();

  /// Releases profiler resources.
  void dispose() {}
}

/// Default [AnalyticsProfiler] that keeps entries in memory for [AnalyticsTool].
///
/// Created by [AnalyticsProfiler.ensureInitialized]. You rarely need to
/// reference this type directly unless replacing [AnalyticsProfiler.instance].
class AnalyticsProfilerMemoryImpl implements AnalyticsProfiler {
  final BehaviorSubject<List<AnalyticsProfileData>> _profileDataSubject =
      BehaviorSubject<List<AnalyticsProfileData>>.seeded([]);

  void _append(AnalyticsProfileData entry) {
    final newData = List<AnalyticsProfileData>.of(_profileDataSubject.value)
      ..add(entry);
    _profileDataSubject.add(newData);
  }

  (DateTime loggedAt, bool canShowDateTime) _getLoggedAtAndCanShowDateTime() {
    final now = DateTime.now();
    final lastLoggedAt = _profileDataSubject.value.lastOrNull?.loggedAt;
    if (lastLoggedAt == null) {
      return (now, true);
    }
    if (now.difference(lastLoggedAt).inMilliseconds > 1000) {
      return (now, true);
    }
    return (lastLoggedAt, false);
  }

  @override
  void logEvent(String name, {Map<String, Object?>? parameters}) {
    final (DateTime loggedAt, bool canShowDateTime) =
        _getLoggedAtAndCanShowDateTime();
    _append(
      AnalyticsProfileData.event(
        name: name,
        loggedAt: loggedAt,
        parameters: parameters,
        canShowDateTime: canShowDateTime,
      ),
    );
  }

  @override
  void logScreenView(String screenName, {Map<String, Object?>? parameters}) {
    final (DateTime loggedAt, bool canShowDateTime) =
        _getLoggedAtAndCanShowDateTime();
    _append(
      AnalyticsProfileData.screenView(
        screenName: screenName,
        loggedAt: loggedAt,
        canShowDateTime: canShowDateTime,
        parameters: parameters,
      ),
    );
  }

  @override
  void setUserId(String? userId) {
    final (DateTime loggedAt, bool canShowDateTime) =
        _getLoggedAtAndCanShowDateTime();
    _append(
      AnalyticsProfileData.userId(
        userId: userId,
        loggedAt: loggedAt,
        canShowDateTime: canShowDateTime,
      ),
    );
  }

  @override
  void setUserProperty(String name, Object? value) {
    final (DateTime loggedAt, bool canShowDateTime) =
        _getLoggedAtAndCanShowDateTime();
    _append(
      AnalyticsProfileData.userProperty(
        name: name,
        value: value,
        loggedAt: loggedAt,
        canShowDateTime: canShowDateTime,
      ),
    );
  }

  @override
  void setGlobalParameters(Map<String, Object?> parameters) {
    final (DateTime loggedAt, bool canShowDateTime) =
        _getLoggedAtAndCanShowDateTime();
    _append(
      AnalyticsProfileData.globalParameters(
        parameters: parameters,
        loggedAt: loggedAt,
        canShowDateTime: canShowDateTime,
      ),
    );
  }

  @override
  Stream<List<AnalyticsProfileData>> getProfileDataStream() =>
      _profileDataSubject.stream;

  @override
  List<AnalyticsProfileData>? getProfileData() =>
      _profileDataSubject.valueOrNull;

  @override
  void clear() {
    _profileDataSubject.add([]);
  }

  @override
  void dispose() {
    _profileDataSubject.close();
  }
}
