import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pretty_json/flutter_pretty_json.dart';

void main() {
  runApp(const JsonViewerApp());
}

class JsonViewerApp extends StatelessWidget {
  const JsonViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Pretty JSON Demo',
      theme: ThemeData.dark(),
      home: const JsonViewerExample(),
    );
  }
}

class JsonViewerExample extends StatefulWidget {
  const JsonViewerExample({super.key});

  static const String _assetPath = 'assets/json_tree_test_data.json';

  @override
  State<JsonViewerExample> createState() => _JsonViewerExampleState();
}

class _JsonViewerExampleState extends State<JsonViewerExample> {
  late final Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = rootBundle.loadString(JsonViewerExample._assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pretty JSON Example')),
      body: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load JSON: ${snapshot.error}'),
              ),
            );
          }

          return PrettyJson(encodedJson: snapshot.data ?? '{}', expandDepth: 1);
        },
      ),
    );
  }
}
