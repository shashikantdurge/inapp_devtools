import 'dart:convert';

import 'package:inapp_devtools/src/core/network_tool/network_tool_http_overrides.dart';

class HttpProfileData {
  final String id;
  Request _request;
  Response? _response;

  Request get request => _request;
  Response? get response => _response;

  set request(Request value) {
    _request = value;
    NetworkToolHttpOverrides.httpProfiler.profileData(this);
  }

  set response(Response? value) {
    _response = value;
    NetworkToolHttpOverrides.httpProfiler.profileData(this);
  }

  final DateTime startTime;
  DateTime? _connectionTime;
  DateTime? get connectionTime => _connectionTime;
  set connectionTime(DateTime? value) {
    _connectionTime = value;
    NetworkToolHttpOverrides.httpProfiler.profileData(this);
  }

  HttpProfileData({
    required this.id,
    required Request request,
    Response? response,
  }) : _request = request,
       _response = response,
       startTime = DateTime.now() {
    NetworkToolHttpOverrides.httpProfiler.profileData(this);
  }

  @override
  String toString() {
    return 'HttpProfileData(id: $id, \n\nrequest: $request, \n\nresponse: $response, \nstartTime: $startTime, \nconnectionTime: $connectionTime)';
  }
}

class Request {
  String method;
  Uri uri;
  Map? headers;
  dynamic body;
  int? contentLength;

  Request({
    required this.method,
    required this.uri,
    this.headers,
    this.body,
    this.contentLength,
  });

  @override
  String toString() {
    return 'Request(method: $method, uri: $uri, headers: $headers, body: $body, contentLength: $contentLength)';
  }
}

/// The response wrapper class for adapters.
///
/// This class should not be used in regular usages.
class Response {
  Response({
    this.data,
    this.statusCode,
    this.statusMessage,
    this.isRedirect = false,
    this.redirects,
    this.contentLength,
    Map<String, List<String>>? headers,
  }) : headers = headers ?? {};

  /// Whether this response is a redirect.
  bool? isRedirect;

  /// The response data.
  String? data;

  List<int> _rawData = <int>[];

  /// HTTP status code.
  int? statusCode;

  /// Content length of the response or null if not specified
  int? contentLength;

  /// Returns the reason phrase corresponds to the status code.
  /// The message can be [HttpRequest.statusText]
  /// or [HttpClientResponse.reasonPhrase].
  String? statusMessage;

  /// Stores redirections during the request.
  List<RedirectRecord>? redirects;

  /// The response headers.
  Map<String, List<String>> headers;

  void appendData(List<int> data) {
    _rawData.addAll(data);
  }

  @override
  String toString() {
    return 'Response(statusCode: $statusCode, statusMessage: $statusMessage, contentLength: $contentLength, headers: $headers, rawData: ${utf8.decode(_rawData)})';
  }
}

/// A record that records the redirection happens during requests,
/// including status code, request method, and the location.
class RedirectRecord {
  const RedirectRecord(this.statusCode, this.method, this.location);

  /// Returns the status code used for the redirect.
  final int statusCode;

  /// Returns the method used for the redirect.
  final String method;

  /// Returns the location for the redirect.
  final Uri location;

  @override
  String toString() {
    return 'RedirectRecord'
        '{statusCode: $statusCode, method: $method, location: $location}';
  }
}
