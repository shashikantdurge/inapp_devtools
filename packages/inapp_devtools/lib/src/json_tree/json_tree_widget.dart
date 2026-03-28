import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'json_tree_data.dart';
import 'json_tree_theme.dart';

/// Displays JSON data as an expandable tree with syntax highlighting.
///
/// Use [JsonTreeTheme] to customize colors
class JsonTreeWidget extends StatefulWidget {
  const JsonTreeWidget({
    required this.json,
    this.expanded = true,
    this.textStyle = const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
    ),
    this.expandDepth,
    super.key,
  });

  /// The JSON data to display. Must be JSON-compatible (Map, List, String, num, bool, null).
  final dynamic json;

  /// Whether the tree is expanded. Defaults to true.
  final bool expanded;

  /// Text style applied to the tree content.
  final TextStyle textStyle;

  /// The depth to expand the tree. Defaults to null.
  final int? expandDepth;

  @override
  State<JsonTreeWidget> createState() => _JsonTreeWidgetState();
}

class _JsonTreeWidgetState extends State<JsonTreeWidget> {
  static const double _indentationWidth = 32.0;
  static const double _padding = 2.0;
  static const double _expandIconSize = 30.0;
  late Size _textSize;
  late double _lineNumberWidth;
  late double rowHeight;

  set textSize(Size value) {
    _textSize = value;
    rowHeight = _textSize.height + _padding * 2;
  }

  late JsonTreeTheme _jsonTheme;
  late List<TreeViewNode<JsonTreeData>> _treeNodes;
  double get indentationWidth => _indentationWidth;
  TreeViewController treeViewController = TreeViewController();

  @override
  void initState() {
    super.initState();
    textSize = _calculateTextSize();
    _constructTree();
  }

  void _constructTree() {
    final (node, nextLineNumber) = buildTreeViewNode(
      widget.json,
      expanded: widget.expanded,
      expandDepth: widget.expandDepth,
    );
    _treeNodes = [node];
    _lineNumberWidth =
        _calculateTextSize('$nextLineNumber').width + _expandIconSize;
  }

  @override
  void didUpdateWidget(covariant JsonTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.textStyle != oldWidget.textStyle) {
      textSize = _calculateTextSize();
    }
    if (jsonEncode(widget.json) != jsonEncode(oldWidget.json) ||
        widget.expandDepth != oldWidget.expandDepth ||
        (widget.expanded != oldWidget.expanded && widget.expandDepth != null)) {
      _constructTree();
    } else if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        treeViewController.expandAll();
      } else {
        treeViewController.collapseAll();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _jsonTheme = _getJsonTheme(context);
  }

  Size _calculateTextSize([String text = ' ']) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: widget.textStyle.fontSize,
          fontWeight: widget.textStyle.fontWeight,
          fontFamily: widget.textStyle.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
      ),
      maxLines: null,
    )..layout(maxWidth: double.infinity);

    return Size(textPainter.size.width * 1.2, textPainter.size.height * 1.2);
  }

  JsonTreeTheme _getJsonTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<JsonTreeTheme>() ??
        (theme.brightness == Brightness.dark
            ? JsonTreeTheme.dark()
            : JsonTreeTheme.light());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: widget.textStyle,
      child: TreeView(
        controller: treeViewController,
        treeRowBuilder: _buildTreeRow,
        treeNodeBuilder: _buildTreeNode,
        indentation: TreeViewIndentationType.none,
        tree: _treeNodes,
      ),
    );
  }

  Span _buildTreeRow(TreeViewNode<JsonTreeData> node) {
    return TreeRow(
      extent: FixedSpanExtent(rowHeight),
      padding: const SpanPadding(),
    );
  }

  Color _getValueColor(PrimitiveType primitiveType) {
    return switch (primitiveType) {
      PrimitiveType.string => _jsonTheme.stringColor,
      PrimitiveType.number => _jsonTheme.numberColor,
      PrimitiveType.boolean => _jsonTheme.booleanColor,
      PrimitiveType.nullValue => _jsonTheme.nullColor,
    };
  }

  Widget _buildKeyText(String key, bool isListItem) {
    final color = isListItem ? _jsonTheme.listIndexColor : _jsonTheme.keyColor;
    return Text(key, style: TextStyle(color: color));
  }

  Widget _buildTreeNode<T extends JsonTreeData>(
    BuildContext context,
    TreeViewNode<T> node,
    AnimationStyle toggleAnimationStyle,
  ) {
    final animationDuration =
        toggleAnimationStyle.duration ?? TreeView.defaultAnimationDuration;
    final animationCurve =
        toggleAnimationStyle.curve ?? TreeView.defaultAnimationCurve;
    final depth = _calculateNodeDepth(node);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLineNumberColumn(node, animationDuration, animationCurve),
        const SizedBox(width: 4),
        // Indentation dividers
        for (int i = 0; i < depth; i++) ...[
          const VerticalDivider(width: 1, thickness: 0.5),
          Padding(padding: EdgeInsets.only(left: indentationWidth)),
        ],
        //  ..._buildIndentationDividers(depth),
        _buildNodeContent(node),
      ],
    );
  }

  int _calculateNodeDepth(TreeViewNode node) {
    final baseDepth = node.depth ?? 0;
    return node.content is BracketTreeData ? baseDepth - 1 : baseDepth;
  }

  Widget _buildLineNumberColumn(
    TreeViewNode<JsonTreeData> node,
    Duration animationDuration,
    Curve animationCurve,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        treeViewController.toggleNode(node);
      },
      child: Material(
        color: _jsonTheme.lineNumberBackgroundColor,
        child: Padding(
          padding: EdgeInsets.all(_padding),
          child: SizedBox(
            width: _lineNumberWidth,
            child: Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "${node.content.lineNumber}",
                    style: TextStyle(color: _jsonTheme.lineNumberTextColor),
                  ),
                  SizedBox.square(
                    dimension: _expandIconSize,
                    child: _buildExpandIcon(
                      node,
                      animationDuration,
                      animationCurve,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildExpandIcon(
    TreeViewNode<JsonTreeData> node,
    Duration animationDuration,
    Curve animationCurve,
  ) {
    if (node.children.isEmpty) return null;

    return AnimatedRotation(
      key: ValueKey<int>(node.content.lineNumber),
      turns: node.isExpanded ? 0.25 : 0.0,
      duration: animationDuration,
      curve: animationCurve,
      child: Icon(
        const IconData(0x25BA),
        size: 14,
        color: _jsonTheme.dropdownIconColor,
      ),
    );
  }

  Widget _buildNodeContent(TreeViewNode<JsonTreeData> node) {
    final isListItem = node.parent?.content is ListTreeData;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, _padding, _padding, _padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (node.content.key case String key) _buildKeyText(key, isListItem),
          ..._buildNodeValue(node.content, node),
        ],
      ),
    );
  }

  List<Widget> _buildNodeValue(
    JsonTreeData content,
    TreeViewNode<JsonTreeData> treeNode,
  ) {
    return switch (content) {
      StringPrimitiveTreeData node => _buildStringValue(node),
      PrimitiveTreeData node => _buildPrimitiveValue(node),
      MapTreeData node => _buildMapValue(node, treeNode),
      ListTreeData node => _buildListValue(node, treeNode),
      BracketTreeData node => _buildClosingBracket(node),
    };
  }

  List<Widget> _buildStringValue(StringPrimitiveTreeData node) {
    return [
      if (node.key != null)
        Text(" : ", style: TextStyle(color: _jsonTheme.colonColor)),
      Text.rich(
        TextSpan(
          children: node.formattedValue.map((e) {
            return switch (e.$2) {
              StringCharType.plain => TextSpan(text: e.$1),
              StringCharType.special => TextSpan(
                text: e.$1,
                style: TextStyle(color: _jsonTheme.specialCharColor),
              ),
            };
          }).toList(),
        ),
        style: TextStyle(color: _getValueColor(node.primitiveType)),
      ),
    ];
  }

  List<Widget> _buildPrimitiveValue(PrimitiveTreeData node) {
    return [
      if (node.key != null)
        Text(" : ", style: TextStyle(color: _jsonTheme.colonColor)),
      Text(
        node.value,
        style: TextStyle(color: _getValueColor(node.primitiveType)),
      ),
    ];
  }

  Widget _buildCollapsedValue(
    String collapsedValue,
    TreeViewNode<JsonTreeData> node,
  ) {
    return GestureDetector(
      onTap: () {
        treeViewController.expandNode(node);
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            collapsedValue,
            style: TextStyle(
              color: _jsonTheme.collapsedValueTextColor,
              backgroundColor: _jsonTheme.collapsedValueBackgroundColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMapValue(
    MapTreeData node,
    TreeViewNode<JsonTreeData> treeNode,
  ) {
    return [
      if (node.key != null)
        Text(" : ", style: TextStyle(color: _jsonTheme.colonColor)),
      Text("{", style: TextStyle(color: _jsonTheme.bracketColor)),
      if (!treeNode.isExpanded) ...[
        _buildCollapsedValue(node.collapsedValue, treeNode),
        Text("}", style: TextStyle(color: _jsonTheme.bracketColor)),
      ],
    ];
  }

  List<Widget> _buildListValue(
    ListTreeData node,
    TreeViewNode<JsonTreeData> treeNode,
  ) {
    return [
      if (node.key != null)
        Text(" : ", style: TextStyle(color: _jsonTheme.colonColor)),
      Text("[", style: TextStyle(color: _jsonTheme.bracketColor)),
      if (!treeNode.isExpanded) ...[
        _buildCollapsedValue(node.collapsedValue, treeNode),
        Text("]", style: TextStyle(color: _jsonTheme.bracketColor)),
      ],
    ];
  }

  List<Widget> _buildClosingBracket(BracketTreeData node) {
    return [Text(node.value, style: TextStyle(color: _jsonTheme.bracketColor))];
  }
}
