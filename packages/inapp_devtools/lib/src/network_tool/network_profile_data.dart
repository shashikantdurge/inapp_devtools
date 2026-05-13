import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'network_profiler.dart';

class NetworkProfileData with ChangeNotifier {
  final String method;
  final Uri uri;
  final NetworkProfileRequestData request;
  final NetworkProfileResponseData response;

  NetworkProfileData({required this.method, required this.uri})
    : request = NetworkProfileRequestData(method: method, uri: uri),
      response = NetworkProfileResponseData(method: method, uri: uri) {
    request.requestStartedAt = DateTime.now();
    NetworkProfiler.instance.profileData(this);
  }

  Map toJson() {
    return {
      'method': method,
      'uri': uri.toString(),
      'request': request.toJson(),
      'response': response.toJson(),
    };
  }

  void sendDataToProfiler() {
    notifyListeners();
  }
}

class NetworkProfileRequestData {
  final Uri uri;
  final String method;
  DateTime? requestStartedAt;
  DateTime? requestEndedAt;
  bool requestInProgress = true;
  Map<String, List<String>>? headers;
  Map? connectionInfo;
  int? contentLength;
  List<String>? cookies;
  bool? followRedirects;
  int? maxRedirects;
  bool? persistentConnection;
  String? error;
  List<int> requestBody = [];

  NetworkProfileRequestData({
    required this.method,
    required this.uri,
    this.headers,
    this.connectionInfo,
    this.contentLength,
    this.cookies,
    this.followRedirects,
    this.maxRedirects,
    this.persistentConnection,
  });

  Map toJson() {
    return {
      'uri': uri.toString(),
      'method': method,
      'requestStartedAt': requestStartedAt?.toIso8601String(),
      'requestEndedAt': requestEndedAt?.toIso8601String(),
      'requestInProgress': requestInProgress,
      'headers': headers,
      'connectionInfo': connectionInfo,
      'contentLength': contentLength,
      'cookies': cookies,
      'followRedirects': followRedirects,
      'maxRedirects': maxRedirects,
      'persistentConnection': persistentConnection,
      'error': error,
      'requestBody': requestBody,
    };
  }
}

class NetworkProfileResponseData {
  final Uri uri;
  final String method;
  DateTime? responseStartedAt;
  DateTime? responseEndedAt;
  bool? responseInProgress;
  Map<String, List<String>>? headers;
  Map? connectionInfo;
  int? contentLength;
  List<String>? cookies;
  bool? isRedirect;
  String? reasonPhrase;
  int? statusCode;
  List<Map>? redirects;
  bool? persistentConnection;
  String? error;
  List<int> responseBody = [];

  NetworkProfileResponseData({required this.uri, required this.method});

  Map toJson() {
    return {
      'uri': uri.toString(),
      'method': method,
      'responseStartedAt': responseStartedAt?.toIso8601String(),
      'responseEndedAt': responseEndedAt?.toIso8601String(),
      'responseInProgress': responseInProgress,
      'headers': headers,
      'connectionInfo': connectionInfo,
      'contentLength': contentLength,
      'cookies': cookies,
      'isRedirect': isRedirect,
      'reasonPhrase': reasonPhrase,
      'redirects': redirects,
      'persistentConnection': persistentConnection,
      'error': error,
      // 'responseBody': utf8.decode(responseBody),
    };
  }
}

extension NetworkProfileDataXUtils on NetworkProfileData {
  /// Builds a POSIX `curl` command (line continuations with `\`) that reproduces
  /// this request as closely as possible.
  ///
  /// Request body is passed as a literal when it is valid UTF-8 without NUL
  /// bytes; otherwise it is embedded via `printf` + `base64 -d` for binary
  /// safety.
  String toCurl() => _networkProfileRequestDataToCurl(request);

  String get statusCodeWithValue {
    if (response.statusCode case final int statusCode) {
      return '$statusCode';
    }
    if (request.requestInProgress == false) {
      return 'Error';
    }
    if (response.statusCode == null && response.reasonPhrase == null) {
      return 'pending';
    }
    return 'Unknown';
  }
}

String _networkProfileRequestDataToCurl(NetworkProfileRequestData data) {
  final lines = <String>[];

  lines.add('-X ${_shellEscapeSingleQuoted(data.method)}');

  final headers = data.headers;
  final hasBody = data.requestBody.isNotEmpty;
  if (headers != null) {
    for (final entry in headers.entries) {
      if (hasBody && _omitHeaderWhenSendingBody(entry.key)) {
        continue;
      }
      for (final value in entry.value) {
        lines.add('-H ${_shellEscapeSingleQuoted('${entry.key}: $value')}');
      }
    }
  }

  final hasCookieHeader =
      headers?.keys.any((k) => k.toLowerCase() == 'cookie') ?? false;
  if (!hasCookieHeader && data.cookies != null && data.cookies!.isNotEmpty) {
    lines.add('-b ${_shellEscapeSingleQuoted(data.cookies!.join('; '))}');
  }

  if (hasBody) {
    lines.add('--data-binary ${_curlDataBinaryArgument(data.requestBody)}');
  }

  lines.add(_shellEscapeSingleQuoted(data.uri.toString()));

  return 'curl \\\n  ${lines.join(' \\\n  ')}';
}

bool _omitHeaderWhenSendingBody(String name) {
  switch (name.toLowerCase()) {
    case 'content-length':
    case 'transfer-encoding':
      return true;
    default:
      return false;
  }
}

String _shellEscapeSingleQuoted(String s) {
  return "'${s.replaceAll("'", "'\\''")}'";
}

String _curlDataBinaryArgument(List<int> bytes) {
  if (_canUseUtf8BodyLiteral(bytes)) {
    return _shellEscapeSingleQuoted(utf8.decode(bytes));
  }
  final b64 = base64Encode(bytes);
  final escapedB64 = _shellEscapeSingleQuoted(b64);
  return '"${r'$'}(printf \'%s\' $escapedB64 | base64 -d)"';
}

bool _canUseUtf8BodyLiteral(List<int> bytes) {
  if (bytes.isEmpty) return true;
  String decoded;
  try {
    decoded = utf8.decode(bytes);
  } catch (_) {
    return false;
  }
  return !decoded.contains('\x00');
}
