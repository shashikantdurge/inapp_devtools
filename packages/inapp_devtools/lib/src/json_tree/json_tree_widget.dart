import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'json_tree_data.dart';
import 'json_tree_theme.dart';

class JsonTreeWidget extends StatefulWidget {
  const JsonTreeWidget({
    required this.json,
    this.textStyle = const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
    ),
    super.key,
  });
  final TextStyle textStyle;
  final dynamic json;

  @override
  State<JsonTreeWidget> createState() => _JsonTreeWidgetState();
}

class _JsonTreeWidgetState extends State<JsonTreeWidget> {
  static const double _indentationWidth = 32.0;
  static const double _padding = 2.0;
  static const double _expandIconSize = 30.0;

  bool isExpanded = true;
  late Size textSize;
  double _lineNumberWidth = 56.0;
  late int linesCount;
  late JsonTreeTheme jsonTheme;
  late List<TreeViewNode<JsonTreeData>> _treeNodes;
  double get indentationWidth => _indentationWidth;
  double get padding => _padding;
  TreeViewController treeViewController = TreeViewController();

  @override
  void initState() {
    super.initState();
    textSize = _calculateTextSize();
    _constructTree();
  }

  void _constructTree() {
    final (node, linesCount) = JsonTreeData.buildTreeViewNode(widget.json);
    _treeNodes = [node];
    this.linesCount = linesCount;
    _lineNumberWidth =
        _calculateTextSize('$linesCount').width + _expandIconSize;
    Future(() => treeViewController.expandAll());
  }

  @override
  void didUpdateWidget(covariant JsonTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.json.toString() != widget.json.toString()) {
      _constructTree();
    }
    if (widget.textStyle != oldWidget.textStyle) {
      textSize = _calculateTextSize();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    jsonTheme = _getJsonTheme(context);
  }

  Size _calculateTextSize([String text = 'abcdefghijklmnopqrstuvwxyz{}[]']) {
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
    // if (kDebugMode) {
    //   _constructTree();
    // }
    return DefaultTextStyle(
      style: widget.textStyle,
      child: TreeView(
        cacheExtent: 56,
        controller: treeViewController,
        treeRowBuilder: _buildTreeRow,
        treeNodeBuilder: _buildTreeNode,
        indentation: TreeViewIndentationType.none,
        tree: _treeNodes,
      ),
    );
  }

  Span _buildTreeRow(TreeViewNode<JsonTreeData> node) {
    final rowHeight = textSize.height + padding * 2;
    return TreeRow(
      extent: FixedSpanExtent(rowHeight),
      padding: const SpanPadding(),
    );
  }

  Color _getValueColor(PrimitiveType primitiveType) {
    return switch (primitiveType) {
      PrimitiveType.string => jsonTheme.stringColor,
      PrimitiveType.number => jsonTheme.numberColor,
      PrimitiveType.boolean => jsonTheme.booleanColor,
      PrimitiveType.nullValue => jsonTheme.nullColor,
    };
  }

  Widget _buildKeyText(String key, bool isListItem) {
    final color = isListItem ? jsonTheme.listIndexColor : jsonTheme.keyColor;
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
        ..._buildIndentationDividers(depth),
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
        color: jsonTheme.lineNumberBackgroundColor,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: SizedBox(
            width: _lineNumberWidth,
            child: Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "${node.content.lineNumber}",
                    style: TextStyle(color: jsonTheme.lineNumberTextColor),
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
        color: jsonTheme.dropdownIconColor,
      ),
    );
  }

  List<Widget> _buildIndentationDividers(int depth) {
    return List.generate(
      depth,
      (_) => [
        const VerticalDivider(width: 1, thickness: 0.5),
        Padding(padding: EdgeInsets.only(left: indentationWidth)),
      ],
    ).expand((widgets) => widgets).toList();
  }

  Widget _buildNodeContent(TreeViewNode<JsonTreeData> node) {
    final isListItem = node.parent?.content is ListTreeData;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, padding, padding, padding),
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
        Text(" : ", style: TextStyle(color: jsonTheme.colonColor)),
      Text.rich(
        TextSpan(
          children: node.formattedValue.map((e) {
            return switch (e.$2) {
              StringCharType.plain => TextSpan(text: e.$1),
              StringCharType.special => TextSpan(
                text: e.$1,
                style: TextStyle(color: Colors.blue),
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
        Text(" : ", style: TextStyle(color: jsonTheme.colonColor)),
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
              color: Colors.grey,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
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
        Text(" : ", style: TextStyle(color: jsonTheme.colonColor)),
      Text("{", style: TextStyle(color: jsonTheme.bracketColor)),
      if (!treeNode.isExpanded) ...[
        _buildCollapsedValue(node.collapsedValue, treeNode),
        Text("}", style: TextStyle(color: jsonTheme.bracketColor)),
      ],
    ];
  }

  List<Widget> _buildListValue(
    ListTreeData node,
    TreeViewNode<JsonTreeData> treeNode,
  ) {
    return [
      if (node.key != null)
        Text(" : ", style: TextStyle(color: jsonTheme.colonColor)),
      Text("[", style: TextStyle(color: jsonTheme.bracketColor)),
      if (!treeNode.isExpanded) ...[
        _buildCollapsedValue(node.collapsedValue, treeNode),
        Text("]", style: TextStyle(color: jsonTheme.bracketColor)),
      ],
    ];
  }

  List<Widget> _buildClosingBracket(BracketTreeData node) {
    return [Text(node.value, style: TextStyle(color: jsonTheme.bracketColor))];
  }
}
