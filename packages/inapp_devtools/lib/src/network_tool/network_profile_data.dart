import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;

abstract class NetworkProfileData extends ChangeNotifier {
  String get method;
  Uri get uri;
  NetworkProfileRequestData get request;
  NetworkProfileResponseData get response;
}

abstract class NetworkProfileRequestData {
  Uri get uri;
  String get method;
  DateTime? get requestStartedAt;
  DateTime? get requestEndedAt;
  bool get requestInProgress;
  Map<String, List<String>>? get headers;
  Map<dynamic, dynamic>? get connectionInfo;
  int? get contentLength;
  List<String>? get cookies;
  bool? get followRedirects;
  int? get maxRedirects;
  bool? get persistentConnection;
  String? get error;
  List<int> get requestBody;
}

abstract class NetworkProfileResponseData {
  Uri get uri;
  String get method;
  DateTime? get responseStartedAt;
  DateTime? get responseEndedAt;
  bool? get responseInProgress;
  Map<String, List<String>>? get headers;
  Map<dynamic, dynamic>? get connectionInfo;
  int? get contentLength;
  List<String>? get cookies;
  bool? get isRedirect;
  String? get reasonPhrase;
  int? get statusCode;
  List<Map<dynamic, dynamic>>? get redirects;
  bool? get persistentConnection;
  String? get error;
  List<int> get responseBody;
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
