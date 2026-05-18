import 'package:flutter/material.dart';

/// Keeps a Dart [List] in sync with an [AnimatedList] / [AnimatedList.separated].
///
/// Mutations update both [_items] and [listKey]'s [AnimatedListState].
class ListModel<E> {
  ListModel({required this.listKey, Iterable<E>? initialItems})
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
