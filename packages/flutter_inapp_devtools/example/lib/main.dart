import 'package:flutter/material.dart';
import 'package:flutter_inapp_devtools/flutter_inapp_devtools.dart';

import 'analytics_tool_screen.dart';
import 'app_theme.dart';
import 'logging_tool_screen.dart';
import 'network_tool_screen.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InAppDevTools(
      color: Colors.blue[200],
      tools: [
        NetworkTool(),
        const LoggingTool(),
        const AnalyticsTool(key: ValueKey('analytics')),
      ],
      child: MaterialApp(
        title: 'InApp DevTools',
        debugShowCheckedModeBanner: false,
        // locale: const Locale('en', 'US'),
        // supportedLocales: const [Locale('en', 'US')],
        // localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ExampleTheme.build(),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.developer_mode, color: ExampleTheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'InApp DevTools',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
      body: ListView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose a tool playground',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _ToolCard(
            icon: Icons.hub_outlined,
            title: 'Network Tool',
            description:
                'Send HTTP requests to public APIs and inspect traffic in the Network devtool.',
            accentColor: const Color(0xFF42A5F5),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NetworkToolScreen(),
              ),
            ),
          ),
          _ToolCard(
            icon: Icons.analytics_outlined,
            title: 'Analytics Tool',
            description:
                'Fire sample analytics events and review them in the Analytics devtool.',
            accentColor: const Color(0xFFC49A6A),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AnalyticsToolScreen(),
              ),
            ),
          ),
          _ToolCard(
            icon: Icons.article_outlined,
            title: 'Logging Tool',
            description:
                'Emit logs at every level and browse them in the Logging devtool.',
            accentColor: const Color(0xFF958EA0),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LoggingToolScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: accentColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: ExampleTheme.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
