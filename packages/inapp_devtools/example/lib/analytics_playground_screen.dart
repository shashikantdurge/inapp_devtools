import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inapp_devtools/inapp_devtools.dart';

/// Tappable list rows that call each [AnalyticsProfiler] API with sample data.
///
/// Open the in-app **Analytics** tool to inspect captured entries.
class AnalyticsPlaygroundScreen extends StatelessWidget {
  const AnalyticsPlaygroundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics playground')),
      body: ListView(
        // itemCount: 10,
        // separatorBuilder: (context, index) => Align(
        //   alignment: Alignment(-1 / 3, 0),
        //   child: SizedBox(
        //     width: 48 + 24,
        //     height: 12,
        //     child: Center(
        //       child: SizedBox(
        //         width: 2,
        //         height: 12,
        //         child: Material(color: Colors.grey),
        //       ),
        //     ),
        //   ),
        // ),
        // itemBuilder: (context, index) => AnalyticsProfileWidget(),
        // padding: EdgeInsets.fromLTRB(100, 12, 0, 8),
        children: [
          ListTile(
            leading: const Icon(Icons.bolt),
            title: const Text('logEvent'),
            subtitle: const Text('sample_event + parameters'),
            onTap: () {
              AnalyticsProfiler.instance.logEvent(
                'fl_initial_paywall_promotional_offer_tap',
                parameters: <String, Object?>{
                  'source': 'playground',
                  'name': 'John Doe',
                  'age': 30,
                  'email': 'john.doe@example.com',
                  'phone': '1234567890',
                  'address': '123 Main St, Anytown, USA',
                  'city': 'Anytown',
                  'state': 'CA',
                  'zip': '12345',
                  'country': 'USA',
                  'gender': 'male',
                  'count': 1,
                  'nested': <String, Object?>{'ok': true},
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.smartphone),
            title: const Text('logScreenView'),
            subtitle: const Text('CheckoutScreen + parameters'),
            onTap: () {
              AnalyticsProfiler.instance.logScreenView(
                'CheckoutScreen',
                parameters: <String, Object?>{'step': 2, 'experiment': 'A'},
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('setUserId'),
            subtitle: const Text('playground_user_42'),
            onTap: () {
              AnalyticsProfiler.instance.setUserId('playground_user_42');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_off_outlined),
            title: const Text('setUserId (clear)'),
            subtitle: const Text('setUserId(null)'),
            onTap: () {
              AnalyticsProfiler.instance.setUserId(null);
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('setUserProperty'),
            subtitle: const Text('plan = premium'),
            onTap: () {
              AnalyticsProfiler.instance.setUserProperty('plan', 'premium');
            },
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('setGlobalParameters'),
            subtitle: const Text('app_version, locale'),
            onTap: () {
              AnalyticsProfiler.instance.setGlobalParameters(<String, Object?>{
                'app_version': '1.0.0-playground',
                'locale': 'en_US',
              });
            },
          ),
        ],
      ),
    );
  }
}

class AnalyticsProfileWidget extends StatefulWidget {
  const AnalyticsProfileWidget({super.key});

  @override
  State<AnalyticsProfileWidget> createState() => _AnalyticsProfileWidgetState();
}

class _AnalyticsProfileWidgetState extends State<AnalyticsProfileWidget> {
  String? _data;
  bool _expanded = false;

  bool get expanded => _data != null && _expanded;

  void showData() {
    final map = {
      'name': 'Analytics Profile',
      'parameter1': 'value1',
      'parameter2': 'value2',
      'parameter3': 'value2',
    };
    _data = JsonEncoder.withIndent('\t').convert(map);
    _expanded = true;
    setState(() {});
  }

  void hideData() {
    _expanded = false;
    setState(() {});
  }

  void _resetDataState() {
    if (!_expanded) {
      _data = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    Widget content;
    if (_data case String data) {
      content = OverflowBox(
        maxWidth: width - 24,
        minWidth: width - 24,
        alignment: Alignment(-1 / 3, -1),
        fit: OverflowBoxFit.deferToChild,
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 48, 0, 0),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(child: Text(data)),
          ),
        ),
      );
    } else {
      content = const SizedBox.shrink();
    }
    return Stack(
      alignment: Alignment(-1 / 3, -1),
      children: [
        AnimatedContainer(
          margin: EdgeInsets.fromLTRB(12, 0, 12, 0),
          onEnd: _resetDataState,
          curve: Curves.easeInOut,
          duration: Duration(milliseconds: 200),
          constraints: expanded
              ? BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                  maxWidth: width,
                  maxHeight: 240,
                )
              : BoxConstraints.tightFor(width: 48, height: 48),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(expanded ? 10 : 100),
          ),
          child: content,
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (expanded) {
              hideData();
            } else {
              showData();
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '12:24:50 PM',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.fromLTRB(12, 0, 12, 0),
                decoration: BoxDecoration(
                  color: expanded ? Colors.transparent : Colors.blue,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(Icons.touch_app),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('user_clicked_button'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
