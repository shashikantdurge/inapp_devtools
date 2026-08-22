import 'dart:async';

import 'package:flutter/material.dart';

/// Keeps a Dart [List] in sync with an [AnimatedList] / [AnimatedList.separated].
///
/// Mutations update both [_items] and [listKey]'s [AnimatedListState].
class _ListModel<E> {
  _ListModel({required this.listKey, Iterable<E>? initialItems})
    : _items = List<E>.from(initialItems ?? <E>[]);

  final GlobalKey<SliverAnimatedListState> listKey;
  final List<E> _items;

  SliverAnimatedListState? get _animatedList => listKey.currentState;

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

  int indexOf(E item) {
    if (_items.indexOf(item) case int index when index >= 0) {
      return _items.length - index - 1;
    }
    return -1;
  }

  E itemAt(int index) => _items[_items.length - index - 1];

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

/// Metadata for a row in [InAppDevToolsScrollView].
///
/// Index `0` is the newest item.
class ItemInfo<E> {
  const ItemInfo({
    required this.index,
    required this.totalCount,
    required this.item,
  });

  final int index;
  final int totalCount;
  final E item;

  bool get isFirst => index == 0;
  bool get isLast => index == totalCount - 1;
}

/// Animated, reverse-ordered list driven by a snapshot [itemsStream].
///
/// Index `0` is the newest item. [itemBuilder] receives the visual index and
/// the insert/remove [animation] from [AnimatedList.separated].
class InAppDevToolsScrollView<E> extends StatefulWidget {
  InAppDevToolsScrollView({
    required this.getItems,
    required this.itemsStream,
    required this.itemBuilder,
    AnimatedItemBuilder? separatorBuilder,
    this.pause = true,
    this.padding = EdgeInsets.zero,
    this.onHiddenItemsCountChanged,
    super.key,
  }) : separatorBuilder =
           separatorBuilder ??
           ((BuildContext context, int index, Animation<double> animation) {
             return const Divider(height: 1, color: Color(0xFF303030));
           });

  final List<E> Function() getItems;
  final Stream<List<E>> itemsStream;
  final Widget Function(BuildContext context, ItemInfo<E> itemInfo) itemBuilder;
  final AnimatedItemBuilder separatorBuilder;
  final bool pause;
  final EdgeInsetsGeometry padding;
  final ValueChanged<int>? onHiddenItemsCountChanged;

  @override
  State<InAppDevToolsScrollView<E>> createState() =>
      _InAppDevToolsScrollViewState<E>();
}

class _InAppDevToolsScrollViewState<E>
    extends State<InAppDevToolsScrollView<E>> {
  final _scrollController = ScrollController();
  final _animatedListKey = GlobalKey<SliverAnimatedListState>();
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
    if (widget.pause && !oldWidget.pause) {
      _onItemsChange(widget.getItems(), animateType: _AnimateType.fade);
      if (widget.pause) {
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
    if (!widget.pause) {
      Future.microtask(
        () =>
            widget.onHiddenItemsCountChanged?.call(data.length - _list.length),
      );
      return;
    }
    Future.microtask(() => widget.onHiddenItemsCountChanged?.call(0));
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

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAnimatedList(
            key: _animatedListKey,
            initialItemCount: _list.length,
            findChildIndexCallback: (key) {
              E value = (key as ValueKey<E>).value;
              final index = _list.indexOf(value);
              return index < 0 ? null : index;
            },
            itemBuilder: (context, index, animation) {
              final item = _list.itemAt(index);
              Widget child = widget.itemBuilder(
                context,
                ItemInfo(index: index, totalCount: _list.length, item: item),
              );
              if (_animateType == _AnimateType.size) {
                child = SizeTransition(
                  sizeFactor: animation,
                  alignment: .bottomCenter,
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
              return KeyedSubtree(key: ValueKey(item), child: child);
            },
          ),
        ],
      ),
    );
  }
}
