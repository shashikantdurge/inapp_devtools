import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:inapp_devtools/src/logging_tool/single_child_pan_viewport.dart';
import 'package:intl/intl.dart';

import 'logging_list_model.dart';

/// Wraps a [LogRecord] with UI state for the logging tool list.
class LogRecordEntry {
  LogRecordEntry(
    this.record, {
    this.expanded = false,
    this.animateType = AnimateType.size,
  });

  final LogRecord record;
  bool expanded;
  AnimateType animateType;

  int get sequenceNumber => record.sequenceNumber;
}

class LoggingTool extends StatefulWidget with InAppDevToolsItem {
  const LoggingTool({super.key});

  @override
  State<LoggingTool> createState() => _LoggingToolState();

  @override
  String get label => 'Logging';

  @override
  void initTool() {
    LoggingProfiler.ensureInitialized();
  }

  @override
  void disposeTool() {
    LoggingProfiler.instance.dispose();
  }
}

enum AnimateType { size, fade }

class _LoggingToolState extends State<LoggingTool> {
  final _scrollController = ScrollController();
  final _animatedListKey = GlobalKey<AnimatedListState>();
  late final ListModel<LogRecordEntry> _list;
  StreamSubscription<List<LogRecord>>? _loggingDataSubscription;
  bool autoUpdateList = true;

  @override
  void initState() {
    super.initState();
    _list = ListModel<LogRecordEntry>(listKey: _animatedListKey);
    _appendRecords(LoggingProfiler.instance.getLoggingData() ?? []);
    _loggingDataSubscription = LoggingProfiler.instance
        .getLoggingDataStream()
        .listen(_onLoggingDataChange);
  }

  void _onLoggingDataChange(
    List<LogRecord> data, {
    AnimateType animateType = AnimateType.size,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    if (!autoUpdateList) {
      return;
    }
    if (data.length < _list.length) {
      _list.removeAll(removedItemBuilder: (context, animation) => SizedBox());
      setState(() {});
      return;
    }
    if (data.length > _list.length) {
      _appendRecords(
        data.sublist(_list.length).toList(),
        animateType: animateType,
        duration: duration,
      );
      setState(() {});
    }
  }

  void _appendRecords(
    List<LogRecord> records, {
    AnimateType animateType = AnimateType.size,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    if (records.isEmpty) {
      return;
    }
    _list.addAll(
      records.map((record) => LogRecordEntry(record, animateType: animateType)),
      duration: duration,
    );
  }

  void _toggleExpanded(LogRecordEntry entry) {
    setState(() => entry.expanded = !entry.expanded);
  }

  @override
  void dispose() {
    _loggingDataSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildLogTile(LogRecordEntry entry, Animation<double> animation) {
    Widget child = _LogTile(
      key: ValueKey(entry.sequenceNumber),
      entry: entry,
      animation: animation,
      onToggleExpanded: () => _toggleExpanded(entry),
    );
    if (entry.animateType == AnimateType.size) {
      child = SizeTransition(
        sizeFactor: animation,
        axisAlignment: 1,
        child: child,
      );
    } else if (entry.animateType == AnimateType.fade) {
      child = DecoratedBoxTransition(
        decoration: DecorationTween(
          begin: BoxDecoration(color: Colors.black),
          end: BoxDecoration(),
        ).animate(animation),
        child: child,
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_list.isEmpty) {
      child = const Center(
        child: Text('Empty', style: TextStyle(color: Colors.grey)),
      );
    } else {
      child = Scrollbar(
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
            return _buildLogTile(_list[_list.length - index - 1], animation);
          },
        ),
      );
    }
    return InAppDevToolsScaffold(
      appBar: InAppDevToolsAppBar(
        customActions: [
          IconButton(
            onPressed: LoggingProfiler.instance.clear,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                autoUpdateList = !autoUpdateList;
              });
              if (autoUpdateList) {
                _onLoggingDataChange(
                  LoggingProfiler.instance.getLoggingData() ?? [],
                  animateType: AnimateType.fade,
                  duration: const Duration(milliseconds: 2000),
                );
              }
            },
            icon: autoUpdateList
                ? const Icon(Icons.pause)
                : const Icon(Icons.play_arrow),
            tooltip: autoUpdateList
                ? 'Pause logging updates'
                : 'Resume logging updates',
          ),
        ],
      ),
      body: child,
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    super.key,
    required this.entry,
    required this.animation,
    required this.onToggleExpanded,
  });

  final LogRecordEntry entry;
  final Animation<double> animation;
  final VoidCallback onToggleExpanded;

  LogRecord get record => entry.record;
  bool get expanded => entry.expanded;

  String _formatLogObject(Object object) {
    if (object is Map || object is Iterable) {
      try {
        return const JsonEncoder.withIndent('  ').convert(object);
      } catch (_) {
        // Fall through to toString.
      }
    }
    return object.toString();
  }

  static const _mutedColor = Color(0xFF958ea0);

  static bool _isDenseLevel(Level level) => switch (level) {
    Level.FINE || Level.FINER || Level.FINEST => true,
    _ => false,
  };

  static Color _levelColor(Level level, {required bool dense}) {
    if (dense) {
      return _mutedColor.withValues(alpha: 0.5);
    }
    return switch (level) {
      Level.WARNING => const Color(0xFFFFB74D),
      Level.SEVERE => const Color(0xFFD7263D),
      Level.SHOUT => const Color(0xFFD7263D),
      _ => const Color(0xFF42A5F5),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dense = _isDenseLevel(record.level);
    final levelColor = _levelColor(record.level, dense: dense);
    final header = _LogTileHeader(
      record: record,
      onToggleExpanded: onToggleExpanded,
      dense: dense,
      levelColor: levelColor,
    );
    final tile = Container(
      decoration: BoxDecoration(
        color: expanded ? Colors.black : Colors.transparent,
      ),
      foregroundDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: levelColor,
            width: expanded ? 3 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record.error != null) ...[
                      const _LogDetailLabel(text: 'Error'),
                      const SizedBox(height: 2),
                      _TwoDimensionalTextBox(
                        text: _formatLogObject(record.error!),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (record.object != null &&
                        record.object != record.error) ...[
                      const _LogDetailLabel(text: 'Object'),
                      const SizedBox(height: 2),
                      _TwoDimensionalTextBox(
                        text: _formatLogObject(record.object!),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (record.stackTrace != null) ...[
                      const _LogDetailLabel(text: 'StackTrace'),
                      const SizedBox(height: 2),
                      _TwoDimensionalTextBox(
                        text: record.stackTrace.toString().trim(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    return tile;
  }
}

class _LogTileHeader extends StatelessWidget {
  const _LogTileHeader({
    required this.record,
    required this.onToggleExpanded,
    required this.dense,
    required this.levelColor,
  });

  final LogRecord record;
  final VoidCallback onToggleExpanded;
  final bool dense;
  final Color levelColor;

  static const _mutedColor = Color(0xFF958ea0);

  static String _formatTime(DateTime time) {
    return DateFormat('HH:mm:ss.SSS').format(time);
  }

  String? _stackTraceCriticalLine() {
    if (record.stackTrace?.toString() case String input) {
      final bracketIndex = input.indexOf('(');
      final beforeBracket = bracketIndex == -1
          ? input
          : input.substring(0, bracketIndex);
      return beforeBracket.replaceFirst(RegExp(r'^#\d+\s+'), '').trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final decorBgColor = dense
        ? Colors.transparent
        : levelColor.withValues(alpha: 0.2);
    final textColorOpacity = dense ? 0.5 : 1.0;
    final textSize = dense ? 12.0 : 14.0;
    final mutedStyle = TextStyle(
      color: _mutedColor.withValues(alpha: textColorOpacity),
      fontSize: 12,
    );
    final onSurface = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: textColorOpacity);
    final levelLabelStyle = TextStyle(
      color: levelColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    return InkWell(
      onTap: onToggleExpanded,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dense)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: record.level.name.toUpperCase(),
                      style: levelLabelStyle,
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(text: _formatTime(record.time), style: mutedStyle),
                    if (record.loggerName.isNotEmpty) ...[
                      const TextSpan(text: '  '),
                      TextSpan(text: record.loggerName, style: mutedStyle),
                    ],
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        child: Icon(
                          Icons.lens,
                          size: 4,
                          color: _mutedColor.withValues(
                            alpha: textColorOpacity,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: record.message,
                      style: TextStyle(fontSize: textSize, color: onSurface),
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                    decoration: BoxDecoration(
                      color: decorBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record.level.name.toUpperCase(),
                      style: levelLabelStyle,
                    ),
                  ),
                  Text(
                    _formatTime(record.time),
                    maxLines: 1,
                    style: mutedStyle,
                  ),
                  if (record.loggerName.isNotEmpty)
                    Flexible(
                      child: Text(
                        record.loggerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mutedStyle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              if (record.message != record.error.toString())
                Text(
                  record.message,
                  style: TextStyle(fontSize: textSize, color: onSurface),
                )
              else
                Text(
                  record.error.runtimeType.toString(),
                  style: TextStyle(fontSize: textSize, color: onSurface),
                ),
              if (_stackTraceCriticalLine() case final String stackTraceLine
                  when stackTraceLine.isNotEmpty)
                Text(
                  stackTraceLine,
                  style: const TextStyle(
                    color: _mutedColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogDetailLabel extends StatelessWidget {
  const _LogDetailLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF958ea0),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _TwoDimensionalTextBox extends StatelessWidget {
  const _TwoDimensionalTextBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 116, minWidth: double.infinity),
      decoration: BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.circular(6),
        // border: Border.all(color: Colors.grey[900]!),
      ),
      child: SingleChildPanViewport(
        padding: const EdgeInsets.all(8),
        child: Text(
          text.trim(),
          softWrap: false,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            fontFamily: 'monospace',
            color: Color(0xFFBDBDBD),
          ),
        ),
      ),
    );
  }
}
