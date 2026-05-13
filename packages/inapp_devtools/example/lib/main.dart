import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iad_image_data_preview/iad_image_data_preview.dart';
import 'package:iad_json_data_preview/iad_json_data_preview.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'analytics_playground_screen.dart';
import 'api_playground_screen.dart';
import 'http_test_framework.dart';

// --- Postman-inspired theme ---
const _postmanBackground = Color(0xFF1E1E1E);
const _postmanSurface = Color(0xFF2D2D2D);
const _postmanOrange = Color(0xFFFF6C37);
const _postmanText = Color(0xFFE0E0E0);
const _postmanTextMuted = Color(0xFF9E9E9E);
const _postmanSuccess = Color(0xFF4CAF50);
const _postmanBorder = Color(0xFF404040);

void main() {
  // FlutterError.onError = (details) {
  //   print('FlutterError: ${details.exceptionAsString()}');
  // };
  AnalyticsProfiler.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InAppDevTools(
      tools: [
        AnalyticsTool(key: ValueKey('4')),
        NetworkTool(
          dataPreviewExtensions: [IadJsonDataPreview(), IadImageDataPreview()],
        ),
      ],
      child: MaterialApp(
        title: 'API Client',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _postmanBackground,
          colorScheme: const ColorScheme.dark(
            primary: _postmanOrange,
            onPrimary: Colors.white,
            surface: _postmanSurface,
            onSurface: _postmanText,
            outline: _postmanBorder,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: _postmanSurface,
            foregroundColor: _postmanText,
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            color: _postmanSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: _postmanBorder, width: 1),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: _postmanOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: _postmanOrange,
              side: const BorderSide(color: _postmanOrange),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: _postmanText, fontSize: 14),
            titleMedium: TextStyle(
              color: _postmanText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            labelLarge: TextStyle(
              color: _postmanText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        home: const MyHomePage(title: 'API Client'),
        // builder: (context, child) {
        //   return InAppDevTools(
        //     color: Colors.purple,
        //     child: child ?? const SizedBox.shrink(),
        //   );
        // },
      ),
    );
  }
}

class RequestTimelineData {
  final Duration connectionTime;
  final Duration ttfbTime;
  final Duration transferTime;
  final Duration totalTime;
  final int? statusCode;
  final String? label;

  const RequestTimelineData({
    required this.connectionTime,
    required this.ttfbTime,
    required this.transferTime,
    required this.totalTime,
    this.statusCode,
    this.label,
  });

  bool get hasData =>
      connectionTime.inMilliseconds > 0 ||
      ttfbTime.inMilliseconds > 0 ||
      transferTime.inMilliseconds > 0;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RequestTimelineData? _timeline;
  bool _isLoading = false;
  String? _error;

  /// Preset scenarios (public hosts only); bodies filled via [HttpTestScenario.resolveBody].
  late final List<HttpTestScenario> _httpPresets =
      HttpTestScenario.resolvedPresets();

  /// Runs a curated [HttpTestScenario] (see [http_test_framework.dart]).
  /// [_httpPresets] entries are already [HttpTestScenario.resolveBody]d.
  Future<void> runHttpScenario(HttpTestScenario scenario) {
    return executeRequest(
      scenario.uri.toString(),
      method: scenario.method,
      headers: scenario.headers,
      bodyBytes: scenario.bodyBytes,
      label: scenario.label,
    );
  }

  /// Single entry point: executes request and updates timeline.
  /// [url] – request URL.
  /// [method] – HTTP method (default GET).
  /// [headers] – optional request headers (e.g. `Content-Type`, `Accept`).
  /// [bodyBytes] – optional request body (UTF-8 or binary).
  /// [label] – short label for the timeline panel.
  /// [onResponse] – optional callback with response stream (e.g. for saving to file).
  Future<void> executeRequest(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    List<int>? bodyBytes,
    String? label,
    Future<void> Function(HttpClientResponse response, List<int> body)?
    onResponse,
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _timeline = null;
    });

    final client = HttpClient();
    final startTime = DateTime.now();
    Duration connectionDuration = Duration.zero;
    Duration ttfbDuration = Duration.zero;
    Duration transferDuration = Duration.zero;
    int? statusCode;

    try {
      final uri = Uri.parse(url);
      // 1. Connection + request line + headers
      final request = await client
          .openUrl(method, uri)
          .timeout(Duration(seconds: 2));
      headers?.forEach((name, value) => request.headers.set(name, value));
      if (bodyBytes != null && bodyBytes.isNotEmpty) {
        request.add(bodyBytes);
      }

      final connectedAt = DateTime.now();
      connectionDuration = connectedAt.difference(startTime);

      // 2. TTFB (first response byte) and transfer
      final HttpClientResponse response = await request.close();
      statusCode = response.statusCode;
      DateTime? ttfbAt;
      final List<int> fullBody = [];

      await for (final chunk in response) {
        ttfbAt ??= DateTime.now();
        fullBody.addAll(chunk);
      }

      final transferDoneAt = DateTime.now();
      // HEAD / empty body: no chunks — treat TTFB as end of response stream.
      ttfbAt ??= transferDoneAt;
      ttfbDuration = ttfbAt.difference(connectedAt);
      transferDuration = transferDoneAt.difference(ttfbAt);

      if (onResponse != null) {
        await onResponse(response, fullBody);
      }

      final totalTime = DateTime.now().difference(startTime);
      setState(() {
        _timeline = RequestTimelineData(
          connectionTime: connectionDuration,
          ttfbTime: ttfbDuration,
          transferTime: transferDuration,
          totalTime: totalTime,
          statusCode: statusCode,
          label: label,
        );
        _isLoading = false;
        _error = null;
      });
    } catch (e, st) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _timeline = null;
      });
      debugPrint('Request error: $e\n$st');
    } finally {
      client.close();
    }
  }

  // --- Use case: simple API call (e.g. GitHub user) ---
  Future<void> fetchGitHubUser() async {
    await executeRequest(
      'https://api.github.com/users/dart-lang',
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'inapp_devtools-example',
      },
    );
  }

  Future<void> fetchGitHubUserError() async {
    await executeRequest(
      'https://api.github.com/users/dart-lang-error?q=123',
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'inapp_devtools-example',
      },
    );
  }

  // --- Use case: request with timing (video URL, no file save) ---
  Future<void> requestWithStopWatch() async {
    await executeRequest(
      'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4',
    );
  }

  // --- Use case: download video to file ---
  Future<void> downloadVideo() async {
    const videoUrl =
        'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/Big_Buck_Bunny_1080_10s_1MB.mp4';
    const savePath = 'my_video.mp4';

    final file = File(savePath);
    final IOSink fileSink = file.openWrite();
    await executeRequest(
      videoUrl,
      onResponse: (response, body) async {
        fileSink.add(body);
        debugPrint('Download complete: ${file.absolute.path}');
      },
    );
    await fileSink.close();
  }

  Future<void> showSnackbar() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Snackbar')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.api, color: _postmanOrange, size: 22),
            const SizedBox(width: 8),
            Text(widget.title),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Analytics playground',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => const AnalyticsPlaygroundScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'API Playground',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => const ApiPlaygroundScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Action buttons (Postman-style request actions) ---
          Container(
            padding: const EdgeInsets.all(16),
            color: _postmanSurface,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _postmanTextMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ActionButton(
                        label: 'GitHub user',
                        icon: Icons.code,
                        onPressed: _isLoading ? null : fetchGitHubUser,
                      ),
                      _ActionButton(
                        label: 'GitHub user Error',
                        icon: Icons.code,
                        onPressed: _isLoading ? null : fetchGitHubUserError,
                      ),
                      _ActionButton(
                        label: 'Video (timing)',
                        icon: Icons.timer,
                        onPressed: _isLoading ? null : requestWithStopWatch,
                      ),
                      _ActionButton(
                        label: 'Download video',
                        icon: Icons.download,
                        onPressed: _isLoading ? null : downloadVideo,
                      ),
                      _ActionButton(
                        label: 'Snackbar',
                        icon: Icons.message,
                        onPressed: _isLoading ? null : showSnackbar,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'HTTP matrix (public APIs)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _postmanTextMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Verbs & payloads: https://httpbingo.org/ — JSON / form / text '
                    'echo. Response types: XML, HTML, PNG, GitHub JSON.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _postmanTextMuted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final scenario in _httpPresets)
                        Tooltip(
                          message: scenario.hint,
                          waitDuration: const Duration(milliseconds: 400),
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => runHttpScenario(scenario),
                            child: Text(scenario.label),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: _postmanBorder),
          // --- Current request timeline ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const _LoadingIndicator()
                  : _error != null
                  ? _ErrorPanel(message: _error!)
                  : _timeline != null && _timeline!.hasData
                  ? _TimelinePanel(data: _timeline!)
                  : const _EmptyState(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_postmanOrange),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sending request...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _postmanTextMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 48, color: _postmanTextMuted),
          const SizedBox(height: 12),
          Text(
            'Send a request to see timeline',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _postmanTextMuted),
          ),
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.data});

  final RequestTimelineData data;

  @override
  Widget build(BuildContext context) {
    final totalMs = data.totalTime.inMilliseconds;
    final maxMs = totalMs > 0 ? totalMs.toDouble() : 1.0;
    final connMs = data.connectionTime.inMilliseconds;
    final ttfbMs = data.ttfbTime.inMilliseconds;
    final transferMs = data.transferTime.inMilliseconds;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response timing',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (data.label != null && data.label!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.label!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _postmanTextMuted,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (data.statusCode != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: data.statusCode! >= 200 && data.statusCode! < 300
                          ? _postmanSuccess.withOpacity(0.2)
                          : _postmanOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${data.statusCode}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: data.statusCode! >= 200 && data.statusCode! < 300
                            ? _postmanSuccess
                            : _postmanOrange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // Visual timeline bar (Postman-style)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    if (connMs > 0)
                      Expanded(
                        flex: (connMs / maxMs * 100).round().clamp(1, 100),
                        child: Container(color: const Color(0xFF2196F3)),
                      ),
                    if (ttfbMs > 0)
                      Expanded(
                        flex: (ttfbMs / maxMs * 100).round().clamp(1, 100),
                        child: Container(color: const Color(0xFFFF9800)),
                      ),
                    if (transferMs > 0)
                      Expanded(
                        flex: (transferMs / maxMs * 100).round().clamp(1, 100),
                        child: Container(color: _postmanSuccess),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(color: const Color(0xFF2196F3)),
                const SizedBox(width: 4),
                Text('Connection', style: _legendStyle(context)),
                const SizedBox(width: 16),
                _LegendDot(color: const Color(0xFFFF9800)),
                const SizedBox(width: 4),
                Text('TTFB', style: _legendStyle(context)),
                const SizedBox(width: 16),
                _LegendDot(color: _postmanSuccess),
                const SizedBox(width: 4),
                Text('Transfer', style: _legendStyle(context)),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: _postmanBorder),
            const SizedBox(height: 16),
            _TimelineRow(label: 'Connection', value: data.connectionTime),
            const SizedBox(height: 10),
            _TimelineRow(
              label: 'Time to first byte (TTFB)',
              value: data.ttfbTime,
            ),
            const SizedBox(height: 10),
            _TimelineRow(label: 'Transfer', value: data.transferTime),
            const SizedBox(height: 14),
            _TimelineRow(label: 'Total', value: data.totalTime, bold: true),
          ],
        ),
      ),
    );
  }

  TextStyle? _legendStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: _postmanTextMuted, fontSize: 12);
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final Duration value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w600 : null,
      color: bold ? _postmanText : _postmanTextMuted,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '${value.inMilliseconds} ms',
          style: style?.copyWith(
            color: bold ? _postmanOrange : _postmanText,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class MyCustomTool extends StatefulWidget with InAppDevToolsItem {
  const MyCustomTool({super.key});

  @override
  State<MyCustomTool> createState() => _MyCustomToolState();

  @override
  String get label => 'Custom Tool';
}

class _MyCustomToolState extends State<MyCustomTool> {
  @override
  Widget build(BuildContext context) {
    return InAppDevToolsScaffold(body: Container(color: Colors.blue));
  }
}
