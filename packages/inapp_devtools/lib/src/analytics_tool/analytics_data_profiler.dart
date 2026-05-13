import 'package:rxdart/subjects.dart';

import 'analytics_profile_data.dart';

abstract class AnalyticsProfiler {
  static AnalyticsProfiler? _instance;

  /// The instance used to record analytics profile entries for DevTools.
  static AnalyticsProfiler get instance {
    if (_instance == null) {
      throw Exception(
        'AnalyticsProfiler not initialized. Call AnalyticsProfiler.ensureInitialized() to initialize it.',
      );
    }
    return _instance!;
  }

  static set instance(AnalyticsProfiler? value) {
    _instance?.dispose();
    _instance = value;
  }

  static void ensureInitialized() {
    _instance ??= AnalyticsProfilerMemoryImpl();
  }

  void logEvent(String name, {Map<String, Object?>? parameters});

  void logScreenView(String screenName, {Map<String, Object?>? parameters});

  void setUserId(String? userId);

  void setUserProperty(String name, Object? value);

  void setGlobalParameters(Map<String, Object?> parameters);

  /// Returns a stream of recorded analytics profile entries (most recent list state).
  Stream<List<AnalyticsProfileData>> getProfileDataStream();

  List<AnalyticsProfileData>? getProfileData();

  void clear();

  void dispose() {}
}

/// A memory implementation of [AnalyticsProfiler].
/// Stores entries in a list and emits updates on a stream.
class AnalyticsProfilerMemoryImpl implements AnalyticsProfiler {
  final BehaviorSubject<List<AnalyticsProfileData>> _profileDataSubject =
      BehaviorSubject<List<AnalyticsProfileData>>.seeded(
        generateAnalyticsProfileData(100),
      );

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

List<AnalyticsProfileData> generateAnalyticsProfileData(int length) {
  return List.generate(
    length,
    (index) => AnalyticsProfileData.event(
      name: 'event_$index',
      parameters: {'parameter_$index': index},
      loggedAt: DateTime.now(),
    ),
  );
}
