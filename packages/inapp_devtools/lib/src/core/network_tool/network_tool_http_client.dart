import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:inapp_devtools/src/core/network_tool/request.dart'
    show Request, HttpProfileData, Response;
import 'package:uuid/uuid.dart';

class NetworkToolHttpClient implements HttpClient {
  final HttpClient _inner;
  NetworkToolHttpClient(this._inner);

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
      id: Uuid().v4(),
      request: Request(method: method, uri: url),
    );
    final request = await _inner.openUrl(method, url);
    profileData.connectionTime = DateTime.now();
    request.done.then((response) {
      profileData.response = Response(statusCode: response.statusCode);
    });
    return NetworkToolHttpClientRequest(request, profileData);
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

class NetworkToolHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final HttpProfileData _profileData;
  final Completer<NetworkToolHttpClientResponse> _responseCompleter;

  NetworkToolHttpClientRequest(this._inner, this._profileData)
    : _responseCompleter = Completer<NetworkToolHttpClientResponse>();

  @override
  bool get bufferOutput => _inner.bufferOutput;

  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;

  @override
  int get contentLength => _inner.contentLength;

  @override
  set contentLength(int value) => _inner.contentLength = value;

  @override
  Encoding get encoding => _inner.encoding;

  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  bool get followRedirects => _inner.followRedirects;

  @override
  set followRedirects(bool value) => _inner.followRedirects = value;

  @override
  int get maxRedirects => _inner.maxRedirects;

  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);

  @override
  void add(List<int> data) => _inner.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _inner.addError(error, stackTrace);
  }

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) =>
      _inner.addStream(stream);

  @override
  Future<HttpClientResponse> close() async {
    final response = await _inner.close();
    _responseCompleter.complete(
      NetworkToolHttpClientResponse(response, _profileData),
    );
    return _responseCompleter.future;
  }

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<HttpClientResponse> get done => Future.wait([
    _inner.done,
    _responseCompleter.future,
  ], eagerError: true).then((list) => list[0]);

  @override
  Future<dynamic> flush() => _inner.flush();

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  String get method => _inner.method;

  @override
  Uri get uri => _inner.uri;

  @override
  void write(Object? object) {
    _inner.write(object);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    _inner.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    _inner.writeCharCode(charCode);
  }

  @override
  void writeln([Object? object = ""]) {
    _inner.writeln(object);
  }
}

class NetworkToolHttpClientResponse implements HttpClientResponse {
  final HttpClientResponse _inner;
  final HttpProfileData _profileData;
  NetworkToolHttpClientResponse(this._inner, this._profileData);

  @override
  int get statusCode => _inner.statusCode;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  int get contentLength => _inner.contentLength;

  @override
  Future<bool> any(bool Function(List<int> element) test) => _inner.any(test);

  @override
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription)? onListen,
    void Function(StreamSubscription<List<int>> subscription)? onCancel,
  }) => _inner.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> event) convert) =>
      _inner.asyncExpand(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) convert) =>
      _inner.asyncMap(convert);

  @override
  Stream<R> cast<R>() => _inner.cast<R>();

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
  Future<Socket> detachSocket() => _inner.detachSocket();

  @override
  Future<E> drain<E>([E? futureValue]) => _inner.drain(futureValue);

  @override
  Future<List<int>> elementAt(int index) => _inner.elementAt(index);

  @override
  Future<bool> every(bool Function(List<int> element) test) =>
      _inner.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) convert) =>
      _inner.expand(convert);

  @override
  Future<List<int>> get first => _inner.first;

  @override
  Future<List<int>> firstWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) => _inner.firstWhere(test, orElse: orElse);

  @override
  Future<S> fold<S>(
    S initialValue,
    S Function(S previous, List<int> element) combine,
  ) => _inner.fold(initialValue, combine);

  @override
  Future<void> forEach(void Function(List<int> element) action) =>
      _inner.forEach(action);

  @override
  Stream<List<int>> handleError(Function onError, {bool test(error)?}) =>
      _inner.handleError(onError, test: test);

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  bool get isBroadcast => _inner.isBroadcast;

  @override
  Future<bool> get isEmpty => _inner.isEmpty;

  @override
  bool get isRedirect => _inner.isRedirect;

  @override
  Future<String> join([String separator = ""]) => _inner.join(separator);

  @override
  Future<List<int>> get last => _inner.last;

  @override
  Future<List<int>> lastWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) => _inner.lastWhere(test, orElse: orElse);

  @override
  Future<int> get length => _inner.length;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final stream = _inner.map((event) {
      _profileData.response?.appendData(event);
      return event;
    });
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Stream<S> map<S>(S Function(List<int> event) convert) => _inner.map(convert);

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  Future<dynamic> pipe(StreamConsumer<List<int>> streamConsumer) =>
      _inner.pipe(streamConsumer);

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => _inner.redirect(method, url, followLoops);

  @override
  List<RedirectInfo> get redirects => _inner.redirects;

  @override
  Future<List<int>> reduce(
    List<int> Function(List<int> previous, List<int> element) combine,
  ) => _inner.reduce(combine);

  @override
  Future<List<int>> get single => _inner.single;

  @override
  Future<List<int>> singleWhere(
    bool Function(List<int> element) test, {
    List<int> Function()? orElse,
  }) => _inner.singleWhere(test, orElse: orElse);

  @override
  Stream<List<int>> skip(int count) => _inner.skip(count);

  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) =>
      _inner.skipWhile(test);

  @override
  Stream<List<int>> take(int count) => _inner.take(count);

  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) =>
      _inner.takeWhile(test);

  @override
  Stream<List<int>> timeout(
    Duration timeLimit, {
    void Function(EventSink<List<int>> sink)? onTimeout,
  }) => _inner.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<List<int>>> toList() => _inner.toList();

  @override
  Future<Set<List<int>>> toSet() => _inner.toSet();

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      _inner.transform(streamTransformer);

  @override
  Stream<List<int>> where(bool Function(List<int> event) test) =>
      _inner.where(test);

  @override
  Future<bool> contains(Object? needle) => _inner.contains(needle);

  @override
  Stream<List<int>> distinct([
    bool Function(List<int> previous, List<int> next)? equals,
  ]) => _inner.distinct(equals);
}
