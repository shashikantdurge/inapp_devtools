import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final json = {'hey4': 0.0005};
    //High depth json
    final highDepthJson = {
      'hey': 0.0005,
      'hey2': 0.0005,
      'hey3': 0.0005,
      'hey4': 0.0005,
      'hey5': 0.0005,
      'hey6': 0.0005,
      'hey7': 0.0005,
      'hey8': {
        'hey9': 0.0005,
        'hey10': 0.0005,
        'hey11': 0.0005,
        'hey12': 0.0005,
        'hey13': 0.0005,
        'hey14': 0.0005,
        'hey15': {
          'hey16': 0.0005,
          'hey17': 0.0005,
          'hey18': 0.0005,
          'hey19': 0.0005,
          'hey20': 0.0005,
          'hey21': {
            'hey22': 0.0005,
            'hey23': 0.0005,
            'hey24': 0.0005,
            'hey25': 0.0005,
            'hey26': 0.0005,
            'hey27': 0.0005,
          },
        },
      },
    };

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('JSON Tree Example')),
        body: Center(
          child: JsonTreeWidget(
            json: highDepthJson,
            expanded: true,
            expandDepth: 2,
          ),
        ),
      ),
    );
  }
}
