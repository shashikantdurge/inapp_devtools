import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';

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

/// App bar for a devtools tool: title opens [InAppDevToolsPickerOverlay],
/// trailing actions scroll horizontally, close collapses the panel.
class InAppDevToolsAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  const InAppDevToolsAppBar({
    super.key,
    this.customActions,
    this.customOverlay,
  });

  /// Extra icon buttons shown before the close control (scrollable row).
  final List<Widget>? customActions;

  /// Painted above the bar content (e.g. modals anchored to the bar).
  final Widget? customOverlay;

  @override
  State<InAppDevToolsAppBar> createState() => _InAppDevToolsAppBarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 42);
}

class _InAppDevToolsAppBarState extends State<InAppDevToolsAppBar> {
  @override
  Widget build(BuildContext context) {
    final controller = InAppDevTools.of(context);
    final selectedTool = controller.tools[controller.selectedToolIndex];
    final theme = InAppDevToolsTheme.of(context);

    return SizedBox.fromSize(
      size: widget.preferredSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(color: theme.appBarBackgroundColor),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsGeometry.all(2),
                child: buildToolDropdownButton(
                  theme,
                  controller.tools,
                  selectedTool,
                ),
              ),
              Expanded(child: buildActionButtons(theme, controller)),
              IconButton(
                onPressed: () {
                  controller.setPanelMode(
                    InAppDevToolsPanelWindowMode.minimized,
                  );
                },
                icon: Icon(Icons.close, color: theme.appBarIconColor),
              ),
            ],
          ),
          ?widget.customOverlay,
        ],
      ),
    );
  }

  DecoratedBox buildActionButtons(
    InAppDevToolsThemeData t,
    InAppDevToolsController controller,
  ) {
    Widget? expandButton;
    if (controller.panelMode == InAppDevToolsPanelWindowMode.windowed) {
      expandButton = IconButton(
        onPressed: () => controller.setPanelMode(.maximized),
        icon: Icon(Icons.fullscreen, color: t.appBarIconColor),
      );
    } else if (controller.panelMode == InAppDevToolsPanelWindowMode.maximized) {
      expandButton = IconButton(
        onPressed: () => controller.setPanelMode(.windowed),
        icon: Icon(Icons.fullscreen_exit, color: t.appBarIconColor),
      );
    }

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            t.appBarBackgroundColor.withAlpha(0),
            t.appBarBackgroundColor,
          ],
          end: Alignment.centerLeft,
          begin: Alignment(-0.5, 0),
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
          reverse: true,
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [...?widget.customActions, ?expandButton],
          ),
        ),
      ),
    );
  }

  Widget buildToolDropdownButton(
    InAppDevToolsThemeData t,
    List<InAppDevToolsItem> tools,
    InAppDevToolsItem selectedTool,
  ) {
    return PopupMenuButton(
      initialValue: selectedTool,
      tooltip: 'Select Tool',
      menuPadding: EdgeInsets.all(2),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          spacing: 4,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 80, minHeight: 42),
              child: Text(
                selectedTool.label,
                style: t.appBarLabelStyle,
                maxLines: 1,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: t.appBarIconColor),
          ],
        ),
      ),
      onSelected: (value) {
        InAppDevTools.of(context).setSelectedToolIndex(tools.indexOf(value));
      },
      itemBuilder: (context) => [
        for (var tool in tools)
          PopupMenuItem(value: tool, height: 42, child: Text(tool.label)),
      ],
    );
  }
}
