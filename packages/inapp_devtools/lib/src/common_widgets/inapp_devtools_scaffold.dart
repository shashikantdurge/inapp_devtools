import 'package:flutter/material.dart';
import 'package:inapp_devtools/src/common_widgets/inapp_devtools_app_bar.dart';
import 'package:inapp_devtools/src/inapp_devtool/theme.dart';

/// Column with a preferred-size [appBar] and an [Expanded] [body] — typical
/// layout for one devtools tool.
class InAppDevToolsScaffold extends StatelessWidget {
  const InAppDevToolsScaffold({
    required this.body,
    this.appBar = const InAppDevToolsAppBar(),
    super.key,
  });

  final Widget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final t = InAppDevToolsTheme.of(context);
    return Material(
      color: t.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          appBar,
          Expanded(child: body),
        ],
      ),
    );
  }
}
