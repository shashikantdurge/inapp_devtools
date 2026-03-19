abstract class NetworkTool {
  void logRequest(NetworkRequest request);
  void logResponse(NetworkResponse response);
}

class NetworkRequest {
  final String id;
  final String method;
  final Uri uri;
  final Map<String, dynamic>? headers;
  final dynamic body;
  final int? contentLength;
  final DateTime timestamp;
  final Duration? timeout;

  NetworkRequest({
    required this.id,
    required this.method,
    required this.uri,
    this.headers,
    this.body,
    this.contentLength,
    DateTime? timestamp,
    this.timeout,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'NetworkRequest(id: $id, method: $method, uri: $uri, headers: $headers, contentLength: $contentLength, timestamp: $timestamp)';
  }
}

class NetworkResponse {
  final String requestId;
  final String method;
  final Uri uri;
  final int statusCode;
  final String? statusMessage;
  final Map<String, dynamic>? headers;
  final dynamic body;
  final int? contentLength;
  final DateTime timestamp;
  final Duration? duration;
  final String? error;

  NetworkResponse({
    required this.requestId,
    required this.method,
    required this.uri,
    required this.statusCode,
    this.statusMessage,
    this.headers,
    this.body,
    this.contentLength,
    DateTime? timestamp,
    this.duration,
    this.error,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
  bool get hasError => error != null;

  @override
  String toString() {
    return 'NetworkResponse(requestId: $requestId, method: $method, uri: $uri, statusCode: $statusCode, statusMessage: $statusMessage, contentLength: $contentLength, duration: $duration, timestamp: $timestamp)';
  }
}
