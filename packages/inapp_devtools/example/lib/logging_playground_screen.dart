import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';

/// Tappable list rows that emit sample [LogRecord]s via the `logging` package.
///
/// Open the in-app **Logging** tool to inspect captured entries.
class LoggingPlaygroundScreen extends StatefulWidget {
  const LoggingPlaygroundScreen({super.key});

  @override
  State<LoggingPlaygroundScreen> createState() =>
      _LoggingPlaygroundScreenState();
}

class _LoggingPlaygroundScreenState extends State<LoggingPlaygroundScreen> {
  final Logger _logger = Logger('playground');
  final Logger _authLogger = Logger('playground.auth');
  final Logger _apiLogger = Logger('playground.api');

  @override
  void initState() {
    super.initState();
    hierarchicalLoggingEnabled = true;
    Logger.root.level = Level.ALL;
    _logger.level = Level.ALL;
    _authLogger.level = Level.ALL;
    _apiLogger.level = Level.ALL;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logging playground')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.bug_report, color: Colors.grey[500]),
            title: const Text('fine'),
            subtitle: const Text('Verbose diagnostic message'),
            onTap: () {
              _logger.fine('Cache warmed for session abc123');
            },
          ),
          ListTile(
            leading: Icon(Icons.tune, color: Colors.blueGrey[300]),
            title: const Text('config'),
            subtitle: const Text('Configuration / setup detail'),
            onTap: () {
              _logger.config('Remote config loaded (build 42)');
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.lightBlue[300]),
            title: const Text('info'),
            subtitle: const Text('General informational log'),
            onTap: () {
              _logger.info('User opened checkout');
            },
          ),
          ListTile(
            leading: Icon(Icons.warning_amber, color: Colors.amber[600]),
            title: const Text('warning'),
            subtitle: const Text('Recoverable issue'),
            onTap: () {
              _logger.warning('Retrying request (attempt 2/3)');
            },
          ),
          ListTile(
            leading: Icon(Icons.error_outline, color: Colors.orange[400]),
            title: const Text('error'),
            subtitle: const Text('Failure with optional error object'),
            onTap: () {
              _logger.log(
                Level.WARNING,
                'Payment failed',
                StateError('card_declined'),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.report, color: Colors.red[400]),
            title: const Text('severe'),
            subtitle: const Text('Critical / unrecoverable'),
            onTap: () {
              _logger.severe(
                'Database connection lost',
                null,
                StackTrace.current,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Named logger — auth'),
            subtitle: const Text('Logger("playground.auth")'),
            onTap: () {
              _authLogger.info('Signed in user_id=playground_user_42', {
                'user_id': 'playground_user_42',
                'user_name': 'John Doe',
                'user_email': 'john.doe@example.com',
              });
            },
          ),
          //Log map object
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Log map object'),
            subtitle: const Text('Map payload as string'),
            onTap: () {
              _logger.info({
                'user_id': 'playground_user_42',
                'user_name': 'John Doe',
                'user_email': 'john.doe@example.com',
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.http),
            title: const Text('Named logger — api'),
            subtitle: const Text('Logger("playground.api")'),
            onTap: () {
              _apiLogger.warning('GET /users/me → 429 Too Many Requests');
            },
          ),
          ListTile(
            leading: const Icon(Icons.layers),
            title: const Text('Burst (5 info logs)'),
            subtitle: const Text('Simulates rapid logging'),
            onTap: () {
              for (var i = 1; i <= 5; i++) {
                _logger.info(
                  'Burst log $i/5',
                  null,
                  StackTrace.fromString('#0 ListTile.build'),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('Structured message'),
            subtitle: const Text('Map payload as string'),
            onTap: () {
              _logger.info({
                'event': 'purchase',
                'amount': 19.99,
                'currency': 'USD',
                'items': ['widget_a', 'widget_b'],
              });
            },
          ),
        ],
      ),
    );
  }
}
