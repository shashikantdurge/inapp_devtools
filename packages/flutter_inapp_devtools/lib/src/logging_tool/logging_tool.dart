import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_devtools/flutter_inapp_devtools.dart';
import '../inapp_devtool/utils.dart';

/// In-app dev tool for inspecting logs from the `package:logging` API.
///
/// ## Example
///
/// ```dart
/// void main() {
///
///   //Required if you're triggering logs before the devtools are mounted.
///   LoggingProfiler.ensureInitialized();
///
///   runApp(
///     InAppDevTools(
///       tools: const [LoggingTool(), NetworkTool(), AnalyticsTool()],
///       child: MaterialApp(home: MyApp()),
///     ),
///   );
/// }
///
/// //Elsewhere in your app:
/// final logger = Logger('my_feature');
/// logger.info('User signed in');
/// logger.warning('Cache miss', error);
/// logger.severe('Request failed', error, stackTrace);
/// ```
///
/// See also:
/// * [InAppDevTools] — host widget and tool registration.
/// * [LoggingProfiler] — attaches to [Logger.root] and stores [LogRecord]s.
/// * [Logger] — `package:logging` logger used by application code.
class LoggingTool extends StatefulWidget with InAppDevToolsItem {
  /// Creates the Logging devtools panel.
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
    LoggingProfiler.instance = null;
  }
}

class _LoggingToolState extends State<LoggingTool>
    with PlayPauseBuilderMixin<LoggingTool> {
  late final Stream<List<LogRecord>> _entriesStream;

  @override
  void initState() {
    super.initState();
    _entriesStream = LoggingProfiler.instance.getLoggingDataStream();
  }

  @override
  Widget build(BuildContext context) {
    return InAppDevToolsScaffold(
      appBar: InAppDevToolsAppBar(
        customActions: [
          IconButton(
            onPressed: LoggingProfiler.instance.clear,
            icon: const Icon(Icons.delete_outline),
          ),
          buildPlayPauseButton(),
        ],
      ),
      body: InAppDevToolsScrollView<LogRecord>(
        pause: !isPaused,
        getItems: () => LoggingProfiler.instance.getLoggingData() ?? [],
        itemsStream: _entriesStream,
        onHiddenItemsCountChanged: setHiddenItemsCount,
        itemBuilder: (context, itemInfo) {
          return _LogTile(
            key: ValueKey(itemInfo.item.sequenceNumber),
            record: itemInfo.item,
          );
        },
      ),
    );
  }
}

class _LogTile extends StatefulWidget {
  const _LogTile({super.key, required this.record});

  final LogRecord record;

  @override
  State<_LogTile> createState() => _LogTileState();
}

class _LogTileState extends State<_LogTile> {
  bool _expanded = false;

  LogRecord get record => widget.record;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  String _formatLogObject(Object object) {
    try {
      if (object is Map || object is Iterable) {
        return const JsonEncoder.withIndent('  ').convert(object);
      } else if ((object as dynamic).toJson() case Object? json) {
        return const JsonEncoder.withIndent('  ').convert(json);
      }
    } catch (_) {
      // Fall through to toString.
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

  Future<void> _showCopyMenu(BuildContext context) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RelativeRect position;
    final box = context.findRenderObject()! as RenderBox;
    position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset(box.size.width, 0), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'all', child: Text('Copy all')),
      const PopupMenuItem(value: 'message', child: Text('Copy message')),
      if (record.object != null)
        const PopupMenuItem(value: 'object', child: Text('Copy object')),
      if (record.error != null)
        const PopupMenuItem(value: 'error', child: Text('Copy error')),
      if (record.stackTrace != null)
        const PopupMenuItem(
          value: 'stackTrace',
          child: Text('Copy stack trace'),
        ),
    ];

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: items,
    );
    if (selected == null || !context.mounted) return;

    final text = switch (selected) {
      'message' => record.message,
      'object' => _formatLogObject4Copy(record.object),
      'error' => _formatLogError4Copy(record.error),
      'stackTrace' => record.stackTrace.toString().trim(),
      'all' => _formatFullRecord(),
      _ => null,
    };
    if (text != null) {
      InAppDevTools.of(context).copyDataCallback(text);
    }
  }

  String _formatLogObject4Copy(Object? object) {
    try {
      final json = JsonEncoder.withIndent('\t').convert(object);
      return 'Object ${object.runtimeType.toString()}:\n$json';
    } catch (_) {
      return 'Object ${object.runtimeType.toString()}: $object';
    }
  }

  String _formatLogError4Copy(Object? error) {
    try {
      final json = JsonEncoder.withIndent('\t').convert(error);
      return 'Error ${error.runtimeType.toString()}:\n$json';
    } catch (_) {
      return 'Error ${error.runtimeType.toString()}: $error';
    }
  }

  String _formatFullRecord() {
    final buffer = StringBuffer()
      ..writeln(
        '[${record.level.name}] ${formatLocalTime(record.time)} ${record.loggerName}',
      );
    if (record.message != record.object.toString()) {
      buffer.writeln(record.message);
    }
    if (record.error != null) {
      buffer.writeln(_formatLogError4Copy(record.error));
    }
    if (record.object != null) {
      buffer.writeln(_formatLogObject4Copy(record.object));
    }
    if (record.stackTrace != null) {
      buffer.writeln(record.stackTrace.toString().trim());
    }
    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final dense = _isDenseLevel(record.level);
    final levelColor = _levelColor(record.level, dense: dense);
    final header = _LogTileHeader(
      record: record,
      onToggleExpanded: _toggleExpanded,
      dense: dense,
      levelColor: levelColor,
    );

    List<Widget>? expandedChildren;
    if (_expanded) {
      expandedChildren = [];
      if (record.error != null) {
        expandedChildren.addAll([
          _LogDetailLabel(
            text: 'Error (${record.error!.runtimeType.toString()})',
          ),
          const SizedBox(height: 2),
          CodeBlockBox(text: _formatLogObject(record.error!)),
          const SizedBox(height: 8),
        ]);
      }

      if (record.object != null && record.object != record.error) {
        expandedChildren.addAll([
          _LogDetailLabel(
            text: 'Object (${record.object!.runtimeType.toString()})',
          ),
          const SizedBox(height: 2),
          CodeBlockBox(text: _formatLogObject(record.object!)),
          const SizedBox(height: 8),
        ]);
      }

      if (record.stackTrace != null) {
        expandedChildren.addAll([
          const _LogDetailLabel(text: 'StackTrace'),
          const SizedBox(height: 2),
          CodeBlockBox(text: record.stackTrace.toString().trim()),
          const SizedBox(height: 8),
        ]);
      }
    }

    final tile = GestureDetector(
      onLongPress: () => _showCopyMenu(context),
      child: Container(
        decoration: BoxDecoration(
          color: _expanded ? Colors.black : Colors.transparent,
        ),
        foregroundDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: levelColor,
              width: _expanded ? 3 : 1,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            bottom: BorderSide(
              color: Color.fromARGB(255, 37, 37, 37),
              width: 1,
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
              if (expandedChildren != null && expandedChildren.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [SizedBox(height: 4), ...expandedChildren],
                  ),
                ),
            ],
          ),
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
    final textSize = dense ? 12.0 : 13.0;
    final mutedStyle = TextStyle(
      color: _mutedColor.withValues(alpha: textColorOpacity),
      fontSize: 12,
    );
    final onSurface = Color.fromARGB(
      255,
      211,
      211,
      211,
    ).withValues(alpha: textColorOpacity);
    final levelLabelStyle = TextStyle(
      color: levelColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    String title;
    final isSameAsError = record.message == record.error.toString();
    final isSameAsObject = record.message == record.object.toString();
    int? maxLines;
    TextOverflow? overflow;
    if (isSameAsError) {
      title = record.error.runtimeType.toString();
    } else if (isSameAsObject) {
      title = record.message;
      maxLines = 1;
      overflow = TextOverflow.ellipsis;
    } else {
      title = record.message;
    }

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
                    TextSpan(
                      text: formatLocalTime(record.time),
                      style: mutedStyle,
                    ),
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
                      text: title,
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
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
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
                    formatLocalTime(record.time),
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
              Text(
                title,
                maxLines: maxLines,
                overflow: overflow,
                style: TextStyle(fontSize: textSize, color: onSurface),
              ),
              if (_stackTraceCriticalLine() case final String stackTraceLine
                  when stackTraceLine.isNotEmpty)
                Text(
                  stackTraceLine,
                  style: const TextStyle(
                    color: _mutedColor,
                    fontSize: 12,
                    // fontStyle: FontStyle.italic,
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
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF958ea0).withValues(),
        // color: Color.fromARGB(255, 116, 114, 119),
        letterSpacing: 0.4,
      ),
    );
  }
}
