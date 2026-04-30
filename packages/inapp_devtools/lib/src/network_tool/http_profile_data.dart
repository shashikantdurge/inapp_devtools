// import 'dart:developer';
// import 'dart:io';
// import 'dart:isolate';
// import 'dart:typed_data';

// class _Proxy {
//   final String? host;
//   final int? port;
//   final String? username;
//   final String? password;
//   final bool isDirect;

//   const _Proxy(String this.host, int this.port, this.username, this.password)
//     : isDirect = false;
//   const _Proxy.direct()
//     : host = null,
//       port = null,
//       username = null,
//       password = null,
//       isDirect = true;

//   bool get isAuthenticated => username != null;
// }

// class _HttpProfileData {
//   static final String isolateId = Service.getIsolateId(Isolate.current)!;

//   final TimelineTask _timeline;
//   late final TimelineTask _responseTimeline;

//   late final String id;
//   final String method;
//   final Uri uri;

//   bool requestInProgress = true;
//   late final int requestStartTimestamp;
//   late final int requestEndTimestamp;
//   Map<String, dynamic>? requestDetails;
//   Map<String, dynamic>? proxyDetails;
//   final List<int> requestBody = <int>[];
//   String? requestError;

//   /// Whether the response-processing has started, and has not yet finished.
//   ///
//   /// This field has three meaningful states:
//   /// * `null`: processing the response has not started.
//   /// * `true`: processing the response has started.
//   /// * `false`: processing the response has finished.
//   bool? responseInProgress;

//   late final int responseStartTimestamp;
//   late final int responseEndTimestamp;
//   Map<String, dynamic>? responseDetails;
//   final List<int> responseBody = <int>[];
//   String? responseError;

//   int _lastUpdateTime = 0;

//   int get lastUpdateTime => _lastUpdateTime;

//   _HttpProfileData(String method, this.uri, TimelineTask? parent)
//     : method = method.toUpperCase(),
//       _timeline = TimelineTask(filterKey: 'HTTP/client', parent: parent) {
//     // Grab the ID from the timeline event so HTTP profile IDs can be matched
//     // to the timeline.
//     id = _timeline.pass().toString();
//     requestInProgress = true;
//     requestStartTimestamp = DateTime.now().microsecondsSinceEpoch;
//     _timeline.start(
//       'HTTP CLIENT $method',
//       arguments: {'method': method.toUpperCase(), 'uri': uri.toString()},
//     );
//     _updated();
//   }

//   void proxyEvent(_Proxy proxy) {
//     proxyDetails = {
//       if (proxy.host != null) 'host': proxy.host,
//       if (proxy.port != null) 'port': proxy.port,
//       if (proxy.username != null) 'username': proxy.username,
//     };
//     _timeline.instant(
//       'Establishing proxy tunnel',
//       arguments: {'proxyDetails': proxyDetails},
//     );
//     _updated();
//   }

//   void appendRequestData(Uint8List data) {
//     requestBody.addAll(data);
//     _updated();
//   }

//   Map<String, List<String>> formatHeaders(HttpHeaders headers) {
//     final newHeaders = <String, List<String>>{};
//     headers.forEach((name, values) {
//       newHeaders[name] = values;
//     });
//     return newHeaders;
//   }

//   Map<String, dynamic>? formatConnectionInfo(
//     HttpConnectionInfo? connectionInfo,
//   ) => connectionInfo == null
//       ? null
//       : {
//           'localPort': connectionInfo.localPort,
//           'remoteAddress': connectionInfo.remoteAddress.address,
//           'remotePort': connectionInfo.remotePort,
//         };

//   void finishRequest({required HttpClientRequest request}) {
//     // TODO(bkonyi): include encoding?
//     requestInProgress = false;
//     requestEndTimestamp = DateTime.now().microsecondsSinceEpoch;
//     requestDetails = <String, dynamic>{
//       // TODO(bkonyi): consider exposing certificate information?
//       // 'certificate': response.certificate,
//       'headers': formatHeaders(request.headers),
//       'connectionInfo': formatConnectionInfo(request.connectionInfo),
//       'contentLength': request.contentLength,
//       'cookies': [for (final cookie in request.cookies) cookie.toString()],
//       'followRedirects': request.followRedirects,
//       'maxRedirects': request.maxRedirects,
//       'method': request.method,
//       'persistentConnection': request.persistentConnection,
//       'uri': request.uri.toString(),
//     };
//     _timeline.finish(arguments: requestDetails);
//     _updated();
//   }

//   /// Marks the response as "started."
//   void startResponse({required HttpClientResponse response}) {
//     responseDetails = <String, dynamic>{
//       'headers': formatHeaders(response.headers),
//       'compressionState': response.compressionState.toString(),
//       'connectionInfo': formatConnectionInfo(response.connectionInfo),
//       'contentLength': response.contentLength,
//       'cookies': [for (final cookie in response.cookies) cookie.toString()],
//       'isRedirect': response.isRedirect,
//       'persistentConnection': response.persistentConnection,
//       'reasonPhrase': response.reasonPhrase,
//       'redirects': [
//         for (final redirect in response.redirects)
//           {
//             'location': redirect.location.toString(),
//             'method': redirect.method,
//             'statusCode': redirect.statusCode,
//           },
//       ],
//       'statusCode': response.statusCode,
//     };

//     assert(!requestInProgress);
//     responseInProgress = true;

//     responseStartTimestamp = DateTime.now().microsecondsSinceEpoch;
//     _responseTimeline = TimelineTask(
//       filterKey: 'HTTP/client',
//       parent: _timeline,
//     );
//     _responseTimeline.start(
//       'HTTP CLIENT response of $method',
//       arguments: {'requestUri': uri.toString(), ...responseDetails!},
//     );
//     _updated();
//   }

//   void finishRequestWithError(String error) {
//     requestInProgress = false;
//     requestEndTimestamp = DateTime.now().microsecondsSinceEpoch;
//     requestError = error;
//     _timeline.finish(arguments: {'error': error});
//     _updated();
//   }

//   /// Marks the response as "finished."
//   void finishResponse() {
//     // Guard against the response being completed more than once or being
//     // completed before the response actually finished starting.
//     if (responseInProgress != true) return;
//     responseInProgress = false;
//     responseEndTimestamp = DateTime.now().microsecondsSinceEpoch;
//     _responseTimeline.finish();
//     _updated();
//   }

//   /// Marks the response as "finished" with an error.
//   void finishResponseWithError(String error) {
//     // Return if `finishResponseWithError` has already been called. Can happen
//     // if the response stream is listened to with `cancelOnError: false`.
//     if (!responseInProgress!) return;
//     responseInProgress = false;
//     responseEndTimestamp = DateTime.now().microsecondsSinceEpoch;
//     responseError = error;
//     _responseTimeline.finish(arguments: {'error': error});
//     _updated();
//   }

//   void appendResponseData(Uint8List data) {
//     responseBody.addAll(data);
//     _updated();
//   }

//   Map<String, dynamic> toJson({required bool ref}) {
//     return <String, dynamic>{
//       'type': '${ref ? '@' : ''}HttpProfileRequest',
//       'id': id,
//       'isolateId': isolateId,
//       'method': method,
//       'uri': uri.toString(),
//       'startTime': requestStartTimestamp,
//       if (!requestInProgress) 'endTime': requestEndTimestamp,
//       if (!requestInProgress)
//         'request': {
//           if (proxyDetails != null) 'proxyDetails': proxyDetails!,
//           if (requestDetails != null) ...requestDetails!,
//           if (requestError != null) 'error': requestError,
//         },
//       if (responseInProgress != null)
//         'response': <String, dynamic>{
//           'startTime': responseStartTimestamp,
//           ...responseDetails!,
//           if (!responseInProgress!) 'endTime': responseEndTimestamp,
//           if (responseError != null) 'error': responseError,
//         },
//       if (!ref) ...{
//         if (!requestInProgress) 'requestBody': requestBody,
//         if (responseInProgress != null) 'responseBody': responseBody,
//       },
//     };
//   }

//   void _updated() => _lastUpdateTime = DateTime.now().microsecondsSinceEpoch;
// }

import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'http_profiler.dart';

class HttpProfileData with ChangeNotifier {
  final String method;
  final Uri uri;
  final HttpProfileRequestData request;
  final HttpProfileResponseData response;

  HttpProfileData({required this.method, required this.uri})
    : request = HttpProfileRequestData(method: method, uri: uri),
      response = HttpProfileResponseData(method: method, uri: uri) {
    request.requestStartedAt = DateTime.now();
    HttpProfiler.instance.profileData(this);
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

class HttpProfileRequestData {
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

  HttpProfileRequestData({
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

class HttpProfileResponseData {
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

  HttpProfileResponseData({required this.uri, required this.method});

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

extension HttpProfileDataXUtils on HttpProfileData {
  /// Builds a POSIX `curl` command (line continuations with `\`) that reproduces
  /// this request as closely as possible.
  ///
  /// Request body is passed as a literal when it is valid UTF-8 without NUL
  /// bytes; otherwise it is embedded via `printf` + `base64 -d` for binary
  /// safety.
  String toCurl() => _httpProfileRequestDataToCurl(request);

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

String _httpProfileRequestDataToCurl(HttpProfileRequestData data) {
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
