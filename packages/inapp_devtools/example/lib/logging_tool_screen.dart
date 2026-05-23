import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';

import 'app_theme.dart';

/// Emits sample log records; inspect them in the in-app **Logging** tool.
class LoggingToolScreen extends StatefulWidget {
  const LoggingToolScreen({super.key});

  @override
  State<LoggingToolScreen> createState() => _LoggingToolScreenState();
}

class _LoggingToolScreenState extends State<LoggingToolScreen> {
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
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.article_outlined, color: ExampleTheme.primary),
            SizedBox(width: 8),
            Text('Logging Tool'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _DevtoolsHint(
            icon: Icons.article_outlined,
            message:
                'Open the in-app devtools panel and select **Logging** to view captured logs.',
          ),
          _LogAction(
            icon: Icons.bug_report,
            iconColor: ExampleTheme.muted,
            title: 'fine',
            subtitle: 'Verbose diagnostic message',
            onTap: () => _logger.fine('Cache warmed for session abc123'),
          ),
          _LogAction(
            icon: Icons.info_outline,
            iconColor: Colors.lightBlue,
            title: 'info',
            subtitle: 'General informational log',
            onTap: () => _logger.info('User opened checkout'),
          ),
          _LogAction(
            icon: Icons.warning_amber,
            iconColor: Colors.amber,
            title: 'warning',
            subtitle: 'Recoverable issue',
            onTap: () => _logger.warning('Retrying request (attempt 2/3)'),
          ),
          _LogAction(
            icon: Icons.error_outline,
            iconColor: Colors.orange,
            title: 'warning (with error)',
            subtitle: 'Log level WARNING with StateError',
            onTap: () => _logger.log(
              Level.WARNING,
              'Payment failed',
              StateError('card_declined'),
            ),
          ),
          _LogAction(
            icon: Icons.report,
            iconColor: Colors.redAccent,
            title: 'severe',
            subtitle: 'Critical failure with stack trace',
            onTap: () => _logger.severe(
              'Database connection lost',
              null,
              StackTrace.current,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _LogAction(
            icon: Icons.account_circle_outlined,
            title: 'Named logger — auth',
            subtitle: 'Logger("playground.auth")',
            onTap: () => _authLogger.info('Signed in user_id=playground_user_42'),
          ),
          _LogAction(
            icon: Icons.http,
            title: 'Named logger — api',
            subtitle: 'Logger("playground.api")',
            onTap: () =>
                _apiLogger.warning('GET /users/me → 429 Too Many Requests'),
          ),
          _LogAction(
            icon: Icons.layers,
            title: 'Burst (5 info logs)',
            subtitle: 'Simulates rapid logging',
            onTap: () {
              for (var i = 1; i <= 5; i++) {
                _logger.info('Burst log $i/5');
              }
            },
          ),
          _LogAction(
            icon: Icons.data_object,
            title: 'Structured message',
            subtitle: 'Map payload as log message',
            onTap: () => _logger.info({
              'event': 'purchase',
              'amount': 19.99,
              'currency': 'USD',
            }),
          ),
        ],
      ),
    );
  }
}

class _LogAction extends StatelessWidget {
  const _LogAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? ExampleTheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _DevtoolsHint extends StatelessWidget {
  const _DevtoolsHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ExampleTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ExampleTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: ExampleTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
