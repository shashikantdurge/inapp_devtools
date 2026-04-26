import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:rxdart/transformers.dart';

import '../http_profile_data.dart';

class IADNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final innerHttpClient = super.createHttpClient(context);
    return IADNetworkHttpClient(innerHttpClient);
  }
}

///Provides the extension methods for the HttpProfileData class to handle the HTTP requests and responses from the IO package.
extension on HttpProfileData {
  void appendRequestData(Uint8List data) {
    request.requestBody.addAll(data);
    log('appendRequestData');
    sendDataToProfiler();
  }

  Map<String, List<String>> _formatHeaders(HttpHeaders headers) {
    final newHeaders = <String, List<String>>{};
    headers.forEach((name, values) {
      newHeaders[name] = values;
    });
    return newHeaders;
  }

  Map? _formatConnectionInfo(HttpConnectionInfo? connectionInfo) =>
      connectionInfo == null
      ? null
      : {
          'localPort': connectionInfo.localPort,
          'remoteAddress': connectionInfo.remoteAddress.address,
          'remotePort': connectionInfo.remotePort,
        };

  void finishRequest({required HttpClientRequest request}) {
    this.request.requestInProgress = false;
    this.request.requestEndedAt = DateTime.now();
    this.request.headers = _formatHeaders(request.headers);
    this.request.connectionInfo = _formatConnectionInfo(request.connectionInfo);
    this.request.contentLength = request.contentLength;
    this.request.cookies = [
      for (final cookie in request.cookies) cookie.toString(),
    ];
    this.request.followRedirects = request.followRedirects;
    this.request.maxRedirects = request.maxRedirects;
    this.request.persistentConnection = request.persistentConnection;
    log('finishRequest');
    sendDataToProfiler();
  }

  void finishRequestWithError(String error) {
    request.requestInProgress = false;
    request.requestEndedAt = DateTime.now();
    request.error = error;
    log('finishRequestWithError');
    sendDataToProfiler();
  }

  /// Marks the response as "finished."
  void finishResponse() {
    // Guard against the response being completed more than once or being
    // completed before the response actually finished starting.
    if (response.responseInProgress != true) return;
    response.responseInProgress = false;
    response.responseEndedAt = DateTime.now();
    log('finishResponse');
    sendDataToProfiler();
  }

  /// Marks the response as "finished" with an error.
  void finishResponseWithError(String error) {
    // Return if `finishResponseWithError` has already been called. Can happen
    // if the response stream is listened to with `cancelOnError: false`.
    if (response.responseInProgress != true) return;
    response.responseInProgress = false;
    response.responseEndedAt = DateTime.now();
    response.error = error;
    log('finishResponseWithError');
    sendDataToProfiler();
  }

  void appendResponseData(List<int> data) {
    response.responseBody.addAll(data);
    log('appendResponseData');
    sendDataToProfiler();
  }

  void startResponse({required HttpClientResponse response}) {
    this.response.headers = _formatHeaders(response.headers);
    this.response.connectionInfo = _formatConnectionInfo(
      response.connectionInfo,
    );
    this.response.contentLength = response.contentLength;
    this.response.cookies = [
      for (final cookie in response.cookies) cookie.toString(),
    ];
    this.response.isRedirect = response.isRedirect;
    this.response.reasonPhrase = response.reasonPhrase;
    this.response.statusCode = response.statusCode;
    this.response.redirects = [
      for (final redirect in response.redirects)
        {
          'location': redirect.location.toString(),
          'method': redirect.method,
          'statusCode': redirect.statusCode,
        },
    ];
    this.response.persistentConnection = response.persistentConnection;
    this.response.responseStartedAt = DateTime.now();
    this.response.responseInProgress = true;
    log('startResponse');
    sendDataToProfiler();
  }
}

class IADNetworkHttpClient implements HttpClient {
  final HttpClient _inner;
  IADNetworkHttpClient(this._inner);

  @override
  Duration get idleTimeout => _inner.idleTimeout;

  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;

  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;

  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;

  @override
  bool get autoUncompress => _inner.autoUncompress;

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  String? get userAgent => _inner.userAgent;

  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final HttpProfileData profileData = HttpProfileData(
      method: method,
      uri: url,
    );
    profileData.sendDataToProfiler();
    final request = await _inner.openUrl(method, url).catchError((error) {
      profileData.finishRequestWithError(error.toString());
      throw error;
    });
    return IADNetworkHttpClientRequest(request, profileData);
  }

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) {
    const int hashMark = 0x23;
    const int questionMark = 0x3f;
    int fragmentStart = path.length;
    int queryStart = path.length;
    for (int i = path.length - 1; i >= 0; i--) {
      var char = path.codeUnitAt(i);
      if (char == hashMark) {
        fragmentStart = i;
        queryStart = i;
      } else if (char == questionMark) {
        queryStart = i;
      }
    }
    String? query;
    if (queryStart < fragmentStart) {
      query = path.substring(queryStart + 1, fragmentStart);
      path = path.substring(0, queryStart);
    }
    Uri uri = Uri(
      scheme: "http",
      host: host,
      port: port,
      path: path,
      query: query,
    );
    return openUrl(method, uri);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open("get", host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl("get", url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open("post", host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl("post", url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open("put", host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl("put", url);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open("delete", host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl("delete", url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open("patch", host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl("patch", url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open("head", host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl("head", url);

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) => _inner.authenticate = f;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addCredentials(url, realm, credentials);

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) => _inner.connectionFactory = f;

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) => _inner.authenticateProxy = f;

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addProxyCredentials(host, port, realm, credentials);

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) => _inner.badCertificateCallback = callback;

  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

///A wrapper class for the HttpClientRequest class to handle the HTTP requests and responses from the IO package.
///
///Sends the request data to [HttpProfileData] for profiling.
class IADNetworkHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final HttpProfileData _profileData;
  final Completer<IADNetworkHttpClientResponse> _responseCompleter =
      Completer<IADNetworkHttpClientResponse>();
  IADNetworkHttpClientRequest(this._inner, this._profileData) {
    done.then((value) {
      _profileData.finishRequest(request: _inner);
      _profileData.startResponse(response: value);
    });
  }

  @override
  Encoding get encoding => _inner.encoding;

  @override
  set encoding(Encoding value) {
    _inner.encoding = value;
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    _inner.abort(exception, stackTrace);
  }

  @override
  void add(List<int> data) {
    _profileData.appendRequestData(Uint8List.fromList(data));
    _inner.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _inner.addError(error, stackTrace);
  }

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) {
    return _inner.addStream(
      stream.map((event) {
        _profileData.appendRequestData(Uint8List.fromList(event));
        return event;
      }),
    );
  }

  @override
  Future<IADNetworkHttpClientResponse> close() {
    return _inner
        .close()
        .then((value) {
          final response = IADNetworkHttpClientResponse(value, _profileData);
          _responseCompleter.complete(response);
          return response;
        })
        .catchError((error) {
          _responseCompleter.completeError(error);
          throw error;
        });
  }

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<IADNetworkHttpClientResponse> get done => _responseCompleter.future;

  @override
  Future<dynamic> flush() {
    return _inner.flush();
  }

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  String get method => _inner.method;

  @override
  Uri get uri => _inner.uri;

  @override
  void write(Object? object) {
    String string = '$object';
    if (string.isNotEmpty) {
      _profileData.appendRequestData(utf8.encode(string));
    }
    _inner.write(object);
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  @override
  void writeln([Object? object = ""]) {
    write('$object\n');
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  bool get bufferOutput => _inner.bufferOutput;

  @override
  set bufferOutput(bool value) {
    _inner.bufferOutput = value;
  }

  @override
  int get contentLength => _inner.contentLength;

  @override
  set contentLength(int value) {
    _inner.contentLength = value;
  }

  @override
  bool get followRedirects => _inner.followRedirects;

  @override
  set followRedirects(bool value) {
    _inner.followRedirects = value;
  }

  @override
  int get maxRedirects => _inner.maxRedirects;

  @override
  set maxRedirects(int value) {
    _inner.maxRedirects = value;
  }

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  set persistentConnection(bool value) {
    _inner.persistentConnection = value;
  }
}

class IADNetworkHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final HttpClientResponse _inner;
  final HttpProfileData _profileData;
  IADNetworkHttpClientResponse(this._inner, this._profileData);

  @override
  int get statusCode => _inner.statusCode;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  int get contentLength => _inner.contentLength;

  @override
  X509Certificate? get certificate => _inner.certificate;

  @override
  HttpClientResponseCompressionState get compressionState =>
      _inner.compressionState;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<Socket> detachSocket() {
    _profileData.finishResponseWithError("Socket detached");
    return _inner.detachSocket();
  }

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  bool get isRedirect => _inner.isRedirect;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _inner
        .transform(
          DoStreamTransformer(
            onDone: () {
              _profileData.finishResponse();
            },
            onError: (e, st) {
              _profileData.finishResponseWithError(e.toString());
            },
            onData: (event) {
              _profileData.appendResponseData(event);
            },
          ),
        )
        .listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => _inner.redirect(method, url, followLoops);

  @override
  List<RedirectInfo> get redirects => _inner.redirects;
}
