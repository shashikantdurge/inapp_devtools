import 'package:rxdart/subjects.dart';

import 'network_profile_data.dart';

abstract class NetworkProfiler {
  static NetworkProfiler? _instance;

  /// The instance of the [NetworkProfiler] used by [NetworkProfileData] to send the profile data.
  static NetworkProfiler get instance {
    if (_instance == null) {
      throw Exception(
        'NetworkProfiler not initialized. Call InAppDevTools.ensureInitialized() to initialize it.',
      );
    }
    return _instance!;
  }

  static set instance(NetworkProfiler? value) {
    _instance?.dispose();
    _instance = value;
  }

  static void ensureInitialized() {
    _instance ??= NetworkProfilerMemoryImpl();
  }

  /// Profiles the given [profileData] and adds it to the list of profile data.
  void profileData(NetworkProfileData profileData);

  /// Returns a stream of the profile data.
  Stream<List<NetworkProfileData>> getProfileDataStream();

  List<NetworkProfileData>? getProfileData();

  void clear();

  void dispose() {}
}

/// A memory implementation of the [NetworkProfiler] interface.
/// Stores the profile data in a list and emits a stream of the profile data.
class NetworkProfilerMemoryImpl implements NetworkProfiler {
  final BehaviorSubject<List<NetworkProfileData>> _profileDataSubject =
      BehaviorSubject<List<NetworkProfileData>>.seeded([]);

  @override
  void profileData(NetworkProfileData profileData) {
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
  Stream<List<NetworkProfileData>> getProfileDataStream() =>
      _profileDataSubject.stream;

  @override
  List<NetworkProfileData>? getProfileData() => _profileDataSubject.valueOrNull;

  @override
  void clear() {
    _profileDataSubject.add([]);
  }

  @override
  void dispose() {
    _profileDataSubject.close();
  }
}
