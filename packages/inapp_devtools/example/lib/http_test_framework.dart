import 'dart:convert';

/// Public echo service used for verbs, custom headers, and echoed bodies.
/// See https://httpbingo.org/
final Uri bingoBaseUri = Uri.https('httpbingo.org');

/// A single reproducible HTTP call for exercising the network devtools.
///
/// All [uri] values point at **public** endpoints (no API keys).
class HttpTestScenario {
  HttpTestScenario({
    required this.id,
    required this.label,
    required this.method,
    required this.uri,
    this.headers = const {},
    this.bodyBytes,
    this.hint = '',
  });

  final String id;
  final String label;
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final List<int>? bodyBytes;

  /// Short note for the UI (payload / expected response shape).
  final String hint;

  /// Curated scenarios: verbs, request content types, response content types.
  static final List<HttpTestScenario> all = <HttpTestScenario>[
    // --- HTTP verbs (JSON echo of request) ---
    HttpTestScenario(
      id: 'get_json',
      label: 'GET',
      method: 'GET',
      uri: Uri.https('httpbingo.org', '/get', {'q': 'devtools'}),
      hint: 'Response: JSON (args + headers echo).',
    ),
    HttpTestScenario(
      id: 'head',
      label: 'HEAD',
      method: 'HEAD',
      uri: Uri.https('httpbingo.org', '/get'),
      hint: 'Response: headers only, no body.',
    ),
    HttpTestScenario(
      id: 'post_json',
      label: 'POST JSON',
      method: 'POST',
      uri: Uri.https('httpbingo.org', '/post'),
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
      },
      hint: 'Payload: JSON. Response: JSON echo.',
    ),
    HttpTestScenario(
      id: 'put_json',
      label: 'PUT',
      method: 'PUT',
      uri: Uri.https('httpbingo.org', '/put'),
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
      },
      hint: 'Payload: JSON. Response: JSON echo.',
    ),
    HttpTestScenario(
      id: 'patch_json',
      label: 'PATCH',
      method: 'PATCH',
      uri: Uri.https('httpbingo.org', '/patch'),
      headers: const {
        'Content-Type': 'application/json; charset=utf-8',
      },
      hint: 'Payload: JSON. Response: JSON echo.',
    ),
    HttpTestScenario(
      id: 'delete',
      label: 'DELETE',
      method: 'DELETE',
      uri: Uri.https('httpbingo.org', '/delete'),
      hint: 'Response: JSON echo.',
    ),
    HttpTestScenario(
      id: 'options',
      label: 'OPTIONS',
      method: 'OPTIONS',
      uri: Uri.https('httpbingo.org', '/get'),
      hint: 'Response: Allow / CORS style headers.',
    ),
    // --- Request body content types ---
    HttpTestScenario(
      id: 'post_form',
      label: 'POST form',
      method: 'POST',
      uri: Uri.https('httpbingo.org', '/post'),
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      hint: 'Payload: urlencoded form. Response: JSON echo.',
    ),
    HttpTestScenario(
      id: 'post_text',
      label: 'POST text',
      method: 'POST',
      uri: Uri.https('httpbingo.org', '/post'),
      headers: const {
        'Content-Type': 'text/plain; charset=utf-8',
      },
      hint: 'Payload: plain text. Response: JSON echo.',
    ),
    // --- Response content types ---
    HttpTestScenario(
      id: 'resp_xml',
      label: 'GET → XML',
      method: 'GET',
      uri: Uri.https('httpbingo.org', '/xml'),
      hint: 'Response: application/xml.',
    ),
    HttpTestScenario(
      id: 'resp_html',
      label: 'GET → HTML',
      method: 'GET',
      uri: Uri.https('httpbingo.org', '/html'),
      hint: 'Response: text/html.',
    ),
    HttpTestScenario(
      id: 'resp_png',
      label: 'GET → PNG',
      method: 'GET',
      uri: Uri.https('httpbingo.org', '/image/png'),
      hint: 'Response: image/png (binary).',
    ),
    HttpTestScenario(
      id: 'resp_json_github',
      label: 'GET → JSON (GitHub)',
      method: 'GET',
      uri: Uri.parse('https://api.github.com/users/dart-lang'),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'inapp_devtools-example',
      },
      hint: 'Response: GitHub JSON API.',
    ),
  ];

  /// Scenarios that need non-null [bodyBytes] filled from [resolveBody].
  static const Set<String> _dynamicBodyIds = {
    'post_json',
    'put_json',
    'patch_json',
    'post_form',
    'post_text',
  };

  /// Returns a copy with [bodyBytes] set for scenarios that use a body.
  HttpTestScenario resolveBody() {
    if (!_dynamicBodyIds.contains(id)) return this;
    switch (id) {
      case 'post_json':
      case 'put_json':
      case 'patch_json':
        return HttpTestScenario(
          id: id,
          label: label,
          method: method,
          uri: uri,
          headers: headers,
          hint: hint,
          bodyBytes: utf8.encode(
            jsonEncode({
              'scenario': id,
              'message': 'inapp_devtools example',
              'n': 42,
            }),
          ),
        );
      case 'post_form':
        return HttpTestScenario(
          id: id,
          label: label,
          method: method,
          uri: uri,
          headers: headers,
          hint: hint,
          bodyBytes: utf8.encode('foo=bar&source=inapp_devtools'),
        );
      case 'post_text':
        return HttpTestScenario(
          id: id,
          label: label,
          method: method,
          uri: uri,
          headers: headers,
          hint: hint,
          bodyBytes: utf8.encode('Plain body line one\nLine two\n'),
        );
      default:
        return this;
    }
  }

  /// Resolved list for UI / iteration (fills dynamic bodies once).
  static List<HttpTestScenario> resolvedPresets() {
    return all.map((s) => s.resolveBody()).toList(growable: false);
  }

  /// GET scenarios focused on response content types for API list examples.
  static List<HttpTestScenario> getContentTypePresets() {
    return <HttpTestScenario>[
      HttpTestScenario(
        id: 'resp_json_httpbingo',
        label: 'GET → JSON (httpbingo)',
        method: 'GET',
        uri: Uri.https('httpbingo.org', '/json'),
        hint: 'Response: application/json.',
      ),
      HttpTestScenario(
        id: 'resp_text',
        label: 'GET → Text',
        method: 'GET',
        uri: Uri.https('httpbingo.org', '/robots.txt'),
        hint: 'Response: text/plain.',
      ),
      HttpTestScenario(
        id: 'resp_xml',
        label: 'GET → XML',
        method: 'GET',
        uri: Uri.https('httpbingo.org', '/xml'),
        hint: 'Response: application/xml.',
      ),
      HttpTestScenario(
        id: 'resp_html',
        label: 'GET → HTML',
        method: 'GET',
        uri: Uri.https('httpbingo.org', '/html'),
        hint: 'Response: text/html.',
      ),
      HttpTestScenario(
        id: 'resp_png',
        label: 'GET → PNG',
        method: 'GET',
        uri: Uri.https('httpbingo.org', '/image/png'),
        hint: 'Response: image/png (binary).',
      ),
      HttpTestScenario(
        id: 'resp_json_github',
        label: 'GET → JSON (GitHub)',
        method: 'GET',
        uri: Uri.parse('https://api.github.com/users/dart-lang'),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'inapp_devtools-example',
        },
        hint: 'Response: GitHub JSON API.',
      ),
    ];
  }
}
