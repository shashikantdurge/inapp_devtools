import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';

import 'app_theme.dart';

/// Emits sample analytics events; inspect them in the in-app **Analytics** tool.
class AnalyticsToolScreen extends StatelessWidget {
  const AnalyticsToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: ExampleTheme.primary),
            SizedBox(width: 8),
            Text('Analytics Tool'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          _DevtoolsHint(
            icon: Icons.analytics_outlined,
            message:
                'Open the in-app devtools panel and select **Analytics** to inspect events.',
          ),
          _AnalyticsAction(
            icon: Icons.bolt,
            title: 'logEvent',
            subtitle: 'Promotional offer tap with rich parameters',
            onTap: _logSampleEvent,
          ),
          _AnalyticsAction(
            icon: Icons.smartphone,
            title: 'logScreenView',
            subtitle: 'CheckoutScreen + parameters',
            onTap: _logScreenView,
          ),
          _AnalyticsAction(
            icon: Icons.person,
            title: 'setUserId',
            subtitle: 'playground_user_42',
            onTap: _setUserId,
          ),
          _AnalyticsAction(
            icon: Icons.person_off_outlined,
            title: 'setUserId (clear)',
            subtitle: 'setUserId(null)',
            onTap: _clearUserId,
          ),
          _AnalyticsAction(
            icon: Icons.badge,
            title: 'setUserProperty',
            subtitle: 'plan = premium',
            onTap: _setUserProperty,
          ),
          _AnalyticsAction(
            icon: Icons.public,
            title: 'setGlobalParameters',
            subtitle: 'app_version, locale',
            onTap: _setGlobalParameters,
          ),
        ],
      ),
    );
  }

  static void _logSampleEvent() {
    AnalyticsProfiler.instance.logEvent(
      'fl_initial_paywall_promotional_offer_tap',
      parameters: <String, Object?>{
        'source': 'playground',
        'name': 'John Doe',
        'age': 30,
        'email': 'john.doe@example.com',
        'count': 1,
        'nested': <String, Object?>{'ok': true},
      },
    );
  }

  static void _logScreenView() {
    AnalyticsProfiler.instance.logScreenView(
      'CheckoutScreen',
      parameters: <String, Object?>{'step': 2, 'experiment': 'A'},
    );
  }

  static void _setUserId() {
    AnalyticsProfiler.instance.setUserId('playground_user_42');
  }

  static void _clearUserId() {
    AnalyticsProfiler.instance.setUserId(null);
  }

  static void _setUserProperty() {
    AnalyticsProfiler.instance.setUserProperty('plan', 'premium');
  }

  static void _setGlobalParameters() {
    AnalyticsProfiler.instance.setGlobalParameters(<String, Object?>{
      'app_version': '1.0.0-playground',
      'locale': 'en_US',
    });
  }
}

class _AnalyticsAction extends StatelessWidget {
  const _AnalyticsAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(icon),
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
