import 'package:rxdart/subjects.dart';

import 'http_profile_data.dart';

abstract class HttpProfiler {
  static HttpProfiler? _instance;

  /// The instance of the [HttpProfiler] used by [HttpProfileData] to send the profile data.
  static HttpProfiler get instance {
    if (_instance == null) {
      throw Exception(
        'HttpProfiler not initialized. Call InAppDevTools.ensureInitialized() to initialize it.',
      );
    }
    return _instance!;
  }

  static set instance(HttpProfiler? value) {
    _instance?.dispose();
    _instance = value;
  }

  static void ensureInitialized() {
    _instance ??= HttpProfilerMemoryImpl();
  }

  /// Profiles the given [profileData] and adds it to the list of profile data.
  void profileData(HttpProfileData profileData);

  /// Returns a stream of the profile data.
  Stream<List<HttpProfileData>> getProfileDataStream();

  List<HttpProfileData>? getProfileData();

  void clear();

  void dispose() {}
}

/// A memory implementation of the [HttpProfiler] interface.
/// Stores the profile data in a list and emits a stream of the profile data.
class HttpProfilerMemoryImpl implements HttpProfiler {
  final BehaviorSubject<List<HttpProfileData>> _profileDataSubject =
      BehaviorSubject<List<HttpProfileData>>.seeded([]);

  @override
  void profileData(HttpProfileData profileData) {
    final existingIndex = _profileDataSubject.value.indexWhere(
      (data) => data == profileData,
    );
    final newData = List.of(_profileDataSubject.value);
    if (existingIndex != -1) {
      newData[existingIndex] = profileData;
    } else {
      newData.add(profileData);
    }
    _profileDataSubject.add(newData);
  }

  @override
  Stream<List<HttpProfileData>> getProfileDataStream() =>
      _profileDataSubject.stream;

  @override
  List<HttpProfileData>? getProfileData() => _profileDataSubject.valueOrNull;

  @override
  void clear() {
    _profileDataSubject.add([]);
  }

  @override
  void dispose() {
    _profileDataSubject.close();
  }
}
