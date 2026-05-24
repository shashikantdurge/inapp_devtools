import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app_theme.dart';

part 'http_test_scenarios.dart';

int _methodChipOrder(String method) {
  const order = <String>[
    'GET',
    'HEAD',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'OPTIONS',
  ];
  final i = order.indexOf(method);
  return i < 0 ? order.length : i;
}

/// Sends sample HTTP traffic; inspect captures in the in-app **Network** tool.
class NetworkToolScreen extends StatefulWidget {
  const NetworkToolScreen({super.key});

  @override
  State<NetworkToolScreen> createState() => _NetworkToolScreenState();
}

class _NetworkToolScreenState extends State<NetworkToolScreen> {
  late final List<HttpTestScenario> _scenarios = HttpTestScenario.all
      .map((s) => s.resolveBody())
      .toList(growable: false);

  late final List<String> _methods = () {
    final set = _scenarios.map((s) => s.method).toSet().toList();
    set.sort((a, b) {
      final cmp = _methodChipOrder(a).compareTo(_methodChipOrder(b));
      return cmp != 0 ? cmp : a.compareTo(b);
    });
    return set;
  }();

  String? _selectedMethod;
  bool _isSending = false;

  List<HttpTestScenario> get _visible {
    if (_selectedMethod == null) return _scenarios;
    return _scenarios.where((s) => s.method == _selectedMethod).toList();
  }

  Future<void> _send(HttpTestScenario scenario) async {
    setState(() => _isSending = true);
    final messenger = ScaffoldMessenger.of(context);
    final client = HttpClient();
    try {
      final request = await client.openUrl(scenario.method, scenario.uri);
      scenario.headers.forEach((name, value) {
        request.headers.set(name, value);
      });
      final body = scenario.bodyBytes;
      if (body != null && body.isNotEmpty) {
        request.add(body);
      }
      final response = await request.close();
      final status = response.statusCode;
      await response.drain();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${scenario.label}: $status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${scenario.label}: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      client.close();
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: ExampleTheme.primary),
            SizedBox(width: 8),
            Text('Network Tool'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DevtoolsHint(
            icon: Icons.hub_outlined,
            message:
                'Open the in-app devtools panel and select **Network** to inspect requests.',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedMethod == null,
                  onSelected: (_) => setState(() => _selectedMethod = null),
                ),
                const SizedBox(width: 8),
                for (final method in _methods) ...[
                  FilterChip(
                    label: Text(method),
                    selected: _selectedMethod == method,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMethod = selected ? method : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          if (_isSending) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _visible.isEmpty
                ? Center(
                    child: Text(
                      'No scenarios for this filter.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: ExampleTheme.muted,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final scenario = _visible[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${scenario.method} ${scenario.uri}',
                                      style: textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      scenario.hint,
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isSending
                                    ? null
                                    : () => _send(scenario),
                                child: const Text('SEND'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
