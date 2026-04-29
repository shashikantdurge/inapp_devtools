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
  Widget? _toolPickerOverlay;

  void _showToolPicker() {
    final controller = InAppDevTools.of(context);
    setState(() {
      _toolPickerOverlay = InAppDevToolsPickerOverlay(
        onClose: _hideToolPicker,
        tools: controller.tools,
        selectedToolIndex: controller.selectedToolIndex,
        onToolSelected: (index) {
          controller.setSelectedToolIndex(index);
          _hideToolPicker();
        },
      );
    });
  }

  void _hideToolPicker() {
    setState(() {
      _toolPickerOverlay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = InAppDevTools.of(context);
    final selectedTool = controller.tools[controller.selectedToolIndex];
    final t = InAppDevToolsTheme.of(context);

    return SizedBox.fromSize(
      size: widget.preferredSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(color: t.appBarBackgroundColor),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsGeometry.all(2),
                child: buildToolDropdownButton(t, selectedTool),
              ),
              Expanded(child: buildActionButtons(t, controller)),
              IconButton(
                onPressed: () {
                  controller.setPanelMode(
                    InAppDevToolsPanelWindowMode.minimized,
                  );
                },
                icon: Icon(Icons.close, color: t.appBarIconColor),
              ),
            ],
          ),
          ?_toolPickerOverlay,
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
        icon: Icon(Icons.open_in_full, color: t.appBarIconColor),
      );
    } else if (controller.panelMode == InAppDevToolsPanelWindowMode.maximized) {
      expandButton = IconButton(
        onPressed: () => controller.setPanelMode(.windowed),
        icon: Icon(Icons.close_fullscreen, color: t.appBarIconColor),
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

  Material buildToolDropdownButton(
    InAppDevToolsThemeData t,
    InAppDevToolsItem selectedTool,
  ) {
    return Material(
      color: t.appBarToolSelectorBackgroundColor,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _showToolPicker,
        borderRadius: BorderRadius.circular(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: t.appBarToolSelectorBorderColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                selectedTool.labelWidget ??
                    Text(selectedTool.label, style: t.appBarLabelStyle),
                const SizedBox(width: 4),
                Icon(Icons.arrow_right, size: 20, color: t.appBarIconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width row under the app bar to pick another [InAppDevToolsItem].
class InAppDevToolsPickerOverlay extends StatelessWidget {
  const InAppDevToolsPickerOverlay({
    super.key,
    required this.onClose,
    required this.tools,
    required this.selectedToolIndex,
    required this.onToolSelected,
  });

  final VoidCallback onClose;
  final List<InAppDevToolsItem> tools;
  final int selectedToolIndex;
  final ValueChanged<int> onToolSelected;

  @override
  Widget build(BuildContext context) {
    final t = InAppDevToolsTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.appBarBackgroundColor,
        border: Border(
          bottom: BorderSide(color: t.pickerBottomBorderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: t.pickerIconColor),
          ),
          Expanded(
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    t.appBarBackgroundColor,
                    t.appBarBackgroundColor.withAlpha(0),
                  ],
                  begin: Alignment.centerRight,
                  end: const Alignment(0.7, 0),
                ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 24, 0),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      onToolSelected(index);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child:
                          tools[index].labelWidget ??
                          Text(
                            tools[index].label,
                            style: t.pickerItemLabelStyle,
                          ),
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return VerticalDivider(
                    width: 16,
                    thickness: 0.5,
                    color: t.pickerListDividerColor,
                  );
                },
                itemCount: tools.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
