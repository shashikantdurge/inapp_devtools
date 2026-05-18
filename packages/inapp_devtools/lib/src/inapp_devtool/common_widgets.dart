import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';

/// Keeps a Dart [List] in sync with an [AnimatedList] / [AnimatedList.separated].
///
/// Mutations update both [_items] and [listKey]'s [AnimatedListState].
class _ListModel<E> {
  _ListModel({required this.listKey, Iterable<E>? initialItems})
    : _items = List<E>.from(initialItems ?? <E>[]);

  final GlobalKey<AnimatedListState> listKey;
  final List<E> _items;

  AnimatedListState? get _animatedList => listKey.currentState;

  int get length => _items.length;

  bool get isEmpty => _items.isEmpty;

  E operator [](int index) => _items[index];

  /// Inserts [items] at [index], one animated insertion per element.
  ///
  /// When inserting at `0`, the first element in [items] ends up below later
  /// insertions at `0` (last iterable element is at index `0`).
  void addAll(
    Iterable<E> items, {
    Duration duration = const Duration(milliseconds: 200),
  }) {
    _items.addAll(items);
    _animatedList?.insertAllItems(0, items.length, duration: duration);
  }

  /// Removes every item from the list and animated list.
  void removeAll({
    required AnimatedRemovedItemBuilder removedItemBuilder,
    Duration duration = Duration.zero,
  }) {
    _animatedList?.removeAllItems(removedItemBuilder, duration: duration);
    _items.clear();
  }
}

enum _AnimateType { size, fade }

/// Animated, reverse-ordered list driven by a snapshot [itemsStream].
///
/// Index `0` is the newest item. [itemBuilder] receives the visual index and
/// the insert/remove [animation] from [AnimatedList.separated].
class InAppDevToolsScrollView<E> extends StatefulWidget {
  const InAppDevToolsScrollView({
    required this.getItems,
    required this.itemsStream,
    required this.itemBuilder,
    this.autoUpdate = true,
    super.key,
  });

  final List<E> Function() getItems;
  final Stream<List<E>> itemsStream;
  final Widget Function(BuildContext context, E item) itemBuilder;
  final bool autoUpdate;

  @override
  State<InAppDevToolsScrollView<E>> createState() =>
      _InAppDevToolsScrollViewState<E>();
}

class _InAppDevToolsScrollViewState<E>
    extends State<InAppDevToolsScrollView<E>> {
  final _scrollController = ScrollController();
  final _animatedListKey = GlobalKey<AnimatedListState>();
  late final _ListModel<E> _list;
  StreamSubscription<List<E>>? _itemsSubscription;
  _AnimateType _animateType = _AnimateType.size;

  Duration get insertDuration => _animateType == _AnimateType.size
      ? const Duration(milliseconds: 200)
      : const Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _list = _ListModel<E>(listKey: _animatedListKey);
    _appendItems(widget.getItems());
    _itemsSubscription = widget.itemsStream.listen(_onItemsChange);
  }

  @override
  void didUpdateWidget(covariant InAppDevToolsScrollView<E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemsStream != widget.itemsStream) {
      _itemsSubscription?.cancel();
      _itemsSubscription = widget.itemsStream.listen(_onItemsChange);
    }
    if (widget.autoUpdate && !oldWidget.autoUpdate) {
      _onItemsChange(widget.getItems(), animateType: _AnimateType.fade);
      if (widget.autoUpdate) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemsChange(
    List<E> data, {
    _AnimateType animateType = _AnimateType.size,
  }) {
    if (!widget.autoUpdate) {
      return;
    }
    _animateType = animateType;
    if (data.length < _list.length) {
      _list.removeAll(removedItemBuilder: (context, animation) => SizedBox());
      return;
    }
    if (data.length > _list.length) {
      _appendItems(data.sublist(_list.length));
    }
  }

  void _appendItems(List<E> items) {
    if (items.isEmpty) {
      return;
    }
    _list.addAll(items, duration: insertDuration);
  }

  E _itemAtVisualIndex(int index) => _list[_list.length - index - 1];

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      child: AnimatedList.separated(
        key: _animatedListKey,
        controller: _scrollController,
        initialItemCount: _list.length,
        separatorBuilder: (context, index, animation) {
          return FadeTransition(
            opacity: animation,
            child: const Divider(height: 1, color: Color(0xFF303030)),
          );
        },
        removedSeparatorBuilder: (context, index, animation) {
          return FadeTransition(
            opacity: animation,
            child: const Divider(height: 4, color: Color(0xFF303030)),
          );
        },
        itemBuilder: (context, index, animation) {
          Widget child = widget.itemBuilder(context, _itemAtVisualIndex(index));
          if (_animateType == _AnimateType.size) {
            child = SizeTransition(
              sizeFactor: animation,
              axisAlignment: 1,
              child: child,
            );
          } else {
            child = DecoratedBoxTransition(
              decoration: DecorationTween(
                begin: BoxDecoration(color: Colors.black),
                end: BoxDecoration(),
              ).animate(animation),
              child: child,
            );
          }
          return child;
        },
      ),
    );
  }
}

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
                overflow: TextOverflow.ellipsis,
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
