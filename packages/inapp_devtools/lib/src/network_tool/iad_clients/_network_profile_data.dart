part of 'iad_http_client.dart';

/// Read-only view over [list]; shares storage (no element copy).
List<int> _readOnlyIntList(List<int> list) => UnmodifiableListView(list);

List<String> _readOnlyStringList(List<String> list) =>
    UnmodifiableListView(list);

Map<String, List<String>> _readOnlyHeadersMap(Map<String, List<String>> map) {
  return UnmodifiableMapView({
    for (final entry in map.entries)
      entry.key: UnmodifiableListView(entry.value),
  });
}

Map<dynamic, dynamic> _readOnlyMap(Map<dynamic, dynamic> map) =>
    UnmodifiableMapView(map);

List<Map<dynamic, dynamic>> _readOnlyRedirectList(
  List<Map<dynamic, dynamic>> list,
) {
  return UnmodifiableListView(list.map(_readOnlyMap).toList(growable: false));
}

class _NetworkProfileData extends NetworkProfileData {
  _NetworkProfileData({required String method, required Uri uri})
    : _method = method,
      _uri = uri,
      _request = _NetworkProfileRequestData(method: method, uri: uri),
      _response = _NetworkProfileResponseData(method: method, uri: uri) {
    _request.requestStartedAt = DateTime.now();
    NetworkProfiler.instance.profileData(this);
  }

  final String _method;
  final Uri _uri;
  final _NetworkProfileRequestData _request;
  final _NetworkProfileResponseData _response;

  @override
  String get method => _method;

  @override
  Uri get uri => _uri;

  @override
  NetworkProfileRequestData get request => _request;

  @override
  NetworkProfileResponseData get response => _response;

  void sendDataToProfiler() {
    notifyListeners();
  }

  void appendRequestData(Uint8List data) {
    _request._requestBody.addAll(data);
    sendDataToProfiler();
  }

  void finishRequest({required HttpClientRequest request}) {
    _request.requestInProgress = false;
    _request.requestEndedAt = DateTime.now();
    _request._headers = _formatHeaders(request.headers);
    _request._connectionInfo = _formatConnectionInfo(request.connectionInfo);
    _request.contentLength = request.contentLength;
    _request._cookies = [
      for (final cookie in request.cookies) cookie.toString(),
    ];
    _request.followRedirects = request.followRedirects;
    _request.maxRedirects = request.maxRedirects;
    _request.persistentConnection = request.persistentConnection;
    sendDataToProfiler();
  }

  void finishRequestWithError(String error) {
    _request.requestInProgress = false;
    _request.requestEndedAt = DateTime.now();
    _request.error = error;
    sendDataToProfiler();
  }

  void startResponse({required HttpClientResponse response}) {
    _response._headers = _formatHeaders(response.headers);
    _response._connectionInfo = _formatConnectionInfo(response.connectionInfo);
    _response.contentLength = response.contentLength;
    _response._cookies = [
      for (final cookie in response.cookies) cookie.toString(),
    ];
    _response.isRedirect = response.isRedirect;
    _response.reasonPhrase = response.reasonPhrase;
    _response.statusCode = response.statusCode;
    _response._redirects = [
      for (final redirect in response.redirects)
        {
          'location': redirect.location.toString(),
          'method': redirect.method,
          'statusCode': redirect.statusCode,
        },
    ];
    _response.persistentConnection = response.persistentConnection;
    _response.responseStartedAt = DateTime.now();
    _response.responseInProgress = true;
    sendDataToProfiler();
  }

  void appendResponseData(List<int> data) {
    _response._responseBody.addAll(data);
    sendDataToProfiler();
  }

  void finishResponse() {
    if (_response.responseInProgress != true) return;
    _response.responseInProgress = false;
    _response.responseEndedAt = DateTime.now();
    sendDataToProfiler();
  }

  void finishResponseWithError(String error) {
    if (_response.responseInProgress != true) return;
    _response.responseInProgress = false;
    _response.responseEndedAt = DateTime.now();
    _response.error = error;
    sendDataToProfiler();
  }

  Map<String, List<String>> _formatHeaders(HttpHeaders headers) {
    final newHeaders = <String, List<String>>{};
    headers.forEach((name, values) {
      newHeaders[name] = values;
    });
    return newHeaders;
  }

  Map<dynamic, dynamic>? _formatConnectionInfo(
    HttpConnectionInfo? connectionInfo,
  ) => connectionInfo == null
      ? null
      : {
          'localPort': connectionInfo.localPort,
          'remoteAddress': connectionInfo.remoteAddress.address,
          'remotePort': connectionInfo.remotePort,
        };
}

class _NetworkProfileRequestData extends NetworkProfileRequestData {
  _NetworkProfileRequestData({required this.method, required this.uri});

  @override
  final Uri uri;

  @override
  final String method;

  @override
  DateTime? requestStartedAt;

  @override
  DateTime? requestEndedAt;

  @override
  bool requestInProgress = true;

  Map<String, List<String>>? _headers;
  Map<dynamic, dynamic>? _connectionInfo;

  @override
  int? contentLength;

  List<String>? _cookies;

  @override
  bool? followRedirects;

  @override
  int? maxRedirects;

  @override
  bool? persistentConnection;

  @override
  String? error;

  final List<int> _requestBody = [];

  @override
  Map<String, List<String>>? get headers =>
      _headers == null ? null : _readOnlyHeadersMap(_headers!);

  @override
  Map<dynamic, dynamic>? get connectionInfo =>
      _connectionInfo == null ? null : _readOnlyMap(_connectionInfo!);

  @override
  List<String>? get cookies =>
      _cookies == null ? null : _readOnlyStringList(_cookies!);

  @override
  List<int> get requestBody => _readOnlyIntList(_requestBody);
}

class _NetworkProfileResponseData extends NetworkProfileResponseData {
  _NetworkProfileResponseData({required this.uri, required this.method});

  @override
  final Uri uri;

  @override
  final String method;

  @override
  DateTime? responseStartedAt;

  @override
  DateTime? responseEndedAt;

  @override
  bool? responseInProgress;

  Map<String, List<String>>? _headers;
  Map<dynamic, dynamic>? _connectionInfo;

  @override
  int? contentLength;

  List<String>? _cookies;

  @override
  bool? isRedirect;

  @override
  String? reasonPhrase;

  @override
  int? statusCode;

  List<Map<dynamic, dynamic>>? _redirects;

  @override
  bool? persistentConnection;

  @override
  String? error;

  final List<int> _responseBody = [];

  @override
  Map<String, List<String>>? get headers =>
      _headers == null ? null : _readOnlyHeadersMap(_headers!);

  @override
  Map<dynamic, dynamic>? get connectionInfo =>
      _connectionInfo == null ? null : _readOnlyMap(_connectionInfo!);

  @override
  List<String>? get cookies =>
      _cookies == null ? null : _readOnlyStringList(_cookies!);

  @override
  List<Map<dynamic, dynamic>>? get redirects =>
      _redirects == null ? null : _readOnlyRedirectList(_redirects!);

  @override
  List<int> get responseBody => _readOnlyIntList(_responseBody);
}
