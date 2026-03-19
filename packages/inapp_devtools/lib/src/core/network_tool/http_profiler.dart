import 'package:inapp_devtools/src/core/network_tool/request.dart';
import 'package:rxdart/subjects.dart';

abstract class HttpProfiler {
  void profileData(HttpProfileData profileData);
  Stream<List<HttpProfileData>> getProfileDataStream();
}

class HttpProfilerMemoryImpl implements HttpProfiler {
  final BehaviorSubject<List<HttpProfileData>> _profileDataSubject =
      BehaviorSubject<List<HttpProfileData>>.seeded([]);

  int _indexOfProfileData(String id) {
    return _profileDataSubject.value.indexWhere((data) => data.id == id);
  }

  @override
  void profileData(HttpProfileData profileData) {
    final existingData = _indexOfProfileData(profileData.id);
    final newData = [..._profileDataSubject.value];
    if (existingData != -1) {
      newData[existingData] = profileData;
    } else {
      newData.add(profileData);
    }
    _profileDataSubject.add(newData);
  }

  @override
  Stream<List<HttpProfileData>> getProfileDataStream() =>
      _profileDataSubject.stream;
}
