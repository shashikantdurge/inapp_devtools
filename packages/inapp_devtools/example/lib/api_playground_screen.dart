import 'dart:io';

import 'package:flutter/material.dart';

import 'http_test_framework.dart';

/// HTTP method sort order for filter chips (stable, predictable UI).
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

/// Full-screen list of [HttpTestScenario.all] with method filter chips and SEND.
class ApiPlaygroundScreen extends StatefulWidget {
  const ApiPlaygroundScreen({super.key});

  @override
  State<ApiPlaygroundScreen> createState() => _ApiPlaygroundScreenState();
}

class _ApiPlaygroundScreenState extends State<ApiPlaygroundScreen> {
  late final List<HttpTestScenario> _resolved = HttpTestScenario.all
      .map((s) => s.resolveBody())
      .toList(growable: false);

  late final List<String> _methods = () {
    final set = _resolved.map((s) => s.method).toSet().toList();
    set.sort((a, b) {
      final cmp = _methodChipOrder(a).compareTo(_methodChipOrder(b));
      return cmp != 0 ? cmp : a.compareTo(b);
    });
    return set;
  }();

  /// `null` means no filter (show all scenarios).
  String? _selectedMethod;

  bool _isSending = false;

  List<HttpTestScenario> get _visible {
    if (_selectedMethod == null) return _resolved;
    return _resolved.where((s) => s.method == _selectedMethod).toList();
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
    final muted = textTheme.bodySmall?.color;

    return Scaffold(
      appBar: AppBar(title: TextField()),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedMethod == null,
                  onSelected: (_) {
                    setState(() => _selectedMethod = null);
                  },
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
                      style: textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _visible.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
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
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
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
