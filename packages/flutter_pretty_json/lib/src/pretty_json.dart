import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'json_tree_data.dart';
import 'theme_extension.dart';

/// Displays JSON data as an expandable tree with syntax highlighting.
///
/// Use [PrettyJsonTheme] to customize colors
class PrettyJson extends StatefulWidget {
  const PrettyJson({
    required this.encodedJson,
    this.expanded = true,
    this.textStyle = const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.normal,
    ),
    this.expandDepth,
    super.key,
  });

  /// The JSON data to display. Must be JSON-compatible (Map, List, String, num, bool, null).
  final String encodedJson;

  /// Whether the tree is expanded. Defaults to true.
  final bool expanded;

  /// Text style applied to the tree content.
  final TextStyle textStyle;

  /// The depth to expand the tree. Defaults to null.
  /// If the [expanded] is set to false, this will be ignored.
  final int? expandDepth;

  @override
  State<PrettyJson> createState() => _PrettyJsonState();
}

class _PrettyJsonState extends State<PrettyJson> {
  static const double _indentationWidth = 32.0;
  static const double _padding = 2.0;
  static const double _expandIconSize = 30.0;
  late Size _textSize;
  late double _lineNumberWidth;
  late double rowHeight;
  TreeViewNode<JsonTreeData>? _selectedNode;

  set textSize(Size value) {
    _textSize = value;
    rowHeight = _textSize.height + _padding * 2;
  }

  late PrettyJsonTheme _jsonTheme;
  late List<TreeViewNode<JsonTreeData>> _treeNodes;
  double get indentationWidth => _indentationWidth;
  TreeViewController treeViewController = TreeViewController();
  final ScrollController horizontalScrollController = ScrollController();
  final ScrollController verticalScrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    textSize = _calculateTextSize();
    _constructTree();
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

  void _constructTree() {
    final (node, nextLineNumber) = buildTreeViewNode(
      widget.encodedJson,
      expanded: widget.expanded,
      expandDepth: widget.expandDepth,
    );
    _treeNodes = [node];
    _lineNumberWidth =
        _calculateTextSize('$nextLineNumber').width + _expandIconSize;
  }

  @override
  void didUpdateWidget(covariant PrettyJson oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.textStyle != oldWidget.textStyle) {
      textSize = _calculateTextSize();
    }
    if (widget.encodedJson != oldWidget.encodedJson ||
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

  PrettyJsonTheme _getJsonTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PrettyJsonTheme>() ??
        (theme.brightness == Brightness.dark
            ? PrettyJsonTheme.dark()
            : PrettyJsonTheme.light());
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: verticalScrollController,
      child: DefaultTextStyle(
        style: widget.textStyle,
        child: TreeView(
          controller: treeViewController,
          treeRowBuilder: _buildTreeRow,
          treeNodeBuilder: _buildTreeNode,
          indentation: TreeViewIndentationType.none,
          horizontalDetails: ScrollableDetails.horizontal(
            controller: horizontalScrollController,
          ),
          verticalDetails: ScrollableDetails.vertical(
            controller: verticalScrollController,
          ),
          tree: _treeNodes,
        ),
      ),
    );
  }

  Span _buildTreeRow(TreeViewNode<JsonTreeData> node) {
    return TreeRow(
      extent: FixedSpanExtent(rowHeight),
      padding: const SpanPadding(),
      backgroundDecoration: SpanDecoration(
        color: isSelected(node)
            ? _jsonTheme.selectedRowColor
            : Colors.transparent,
      ),
      recognizerFactories: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 300),
              ),
              (LongPressGestureRecognizer instance) {
                instance.onLongPressStart = (details) =>
                    _showJsonNodeContextMenu(node, details.globalPosition);
              },
            ),
      },
    );
  }

  RelativeRect _getMenuPositionForNode(
    TreeViewNode<JsonTreeData> node,
    BoxConstraints constraints,
    Offset? globalTapPosition,
  ) {
    final navigator = Navigator.of(context);
    final overlayObject = navigator.overlay?.context.findRenderObject();
    final treeObject = context.findRenderObject();

    if (overlayObject is! RenderBox || treeObject is! RenderBox) {
      return RelativeRect.fromSize(Rect.zero, constraints.biggest);
    }

    final activeIndex = treeViewController.getActiveIndexFor(node) ?? 0;
    final rowTop = rowHeight * activeIndex;

    // Anchor the menu to the bottom of the clicked row rect in overlay coordinates.
    final anchorRect = Rect.fromLTWH(
      globalTapPosition?.dx ??
          treeObject.localToGlobal(Offset.zero, ancestor: overlayObject).dx,
      treeObject.localToGlobal(Offset(0, rowTop), ancestor: overlayObject).dy -
          verticalScrollController.offset +
          rowHeight,
      treeObject.size.width,
      rowHeight,
    );

    return RelativeRect.fromRect(anchorRect, Offset.zero & overlayObject.size);
  }

  /// Postman-inspired context menu.
  Future<void> _showJsonNodeContextMenu(
    TreeViewNode<JsonTreeData> node,
    Offset positionRelativeToGlobal,
  ) async {
    final theme = Theme.of(context);
    final menuBg = theme.colorScheme.surface;
    final borderColor = theme.dividerColor;
    final textColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
    final itemStyle = TextStyle(
      color: textColor,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
    );

    final selectedNode = switch (node.content) {
      BracketTreeData() => node.parent!,
      _ => node,
    };
    setState(() {
      _selectedNode = selectedNode;
    });

    final optionItems = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'copy_value',
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('Copy Value', style: itemStyle),
      ),
      if (selectedNode.content.key != null) ...[
        PopupMenuItem<String>(
          value: 'copy_name',
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('Copy Name', style: itemStyle),
        ),
        PopupMenuItem<String>(
          value: 'copy_property_path',
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('Copy property path', style: itemStyle),
        ),
      ],
      if (selectedNode.content is StringPrimitiveTreeData) ...[
        PopupMenuItem<String>(
          value: 'copy_string_contents',
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('Copy string contents', style: itemStyle),
        ),
        PopupMenuItem<String>(
          value: 'copy_string_as_json_literal',
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('Copy string as JSON literal', style: itemStyle),
        ),
      ],
      if (selectedNode.children.isNotEmpty) ...[
        PopupMenuDivider(height: 2, indent: 8, endIndent: 8),
        PopupMenuItem<String>(
          value: 'expand_all',
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('Expand all', style: itemStyle),
        ),
        PopupMenuItem<String>(
          value: 'collapse_all',
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('Collapse all', style: itemStyle),
        ),
      ],
    ];

    final selectedOption = await showMenu<String>(
      context: context,
      positionBuilder: (_, constraints) =>
          _getMenuPositionForNode(node, constraints, positionRelativeToGlobal),
      color: menuBg,
      elevation: 12,
      clipBehavior: Clip.hardEdge,
      shadowColor: theme.shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: borderColor),
      ),
      menuPadding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 168),
      items: optionItems,
    );
    setState(() {
      _selectedNode = null;
    });
    if (selectedOption != null) {
      _performNodeAction(selectedOption, selectedNode);
    }
  }

  void _performNodeAction(String action, TreeViewNode<JsonTreeData> node) {
    switch (action) {
      case 'copy_name':
        assert(
          node.content.key != null,
          'Key should not be null, if you see this, please report an issue to the developer',
        );
        Clipboard.setData(ClipboardData(text: node.content.key!));
        break;
      case 'copy_value':
      case 'copy_string_contents':
        assert(
          node.content.getCopyableValue != null,
          'Copyable value should not be null, if you see this, please report an issue to the developer',
        );
        Clipboard.setData(
          ClipboardData(text: node.content.getCopyableValue!.call()!),
        );
        break;
      case 'copy_property_path':
        final path = _getPropertyPath(node);
        assert(
          path != null,
          'Property path should not be null, if you see this, please report an issue to the developer',
        );
        Clipboard.setData(ClipboardData(text: path!));
        break;
      case 'copy_string_as_json_literal':
        assert(
          node.content is StringPrimitiveTreeData,
          'Node content should be a StringPrimitiveTreeData, if you see this, please report an issue to the developer',
        );
        final stringNode = node.content as StringPrimitiveTreeData;
        Clipboard.setData(ClipboardData(text: stringNode.value));
        break;
      case 'expand_all':
        void expandNode(TreeViewNode<JsonTreeData> node) {
          treeViewController.expandNode(node);
          for (final child in node.children) {
            if (child.children.isNotEmpty) {
              expandNode(child);
            }
          }
        }
        expandNode(node);
        break;
      case 'collapse_all':
        void collapseNode(TreeViewNode<JsonTreeData> node) {
          treeViewController.collapseNode(node);
          for (final child in node.children) {
            if (child.children.isNotEmpty) {
              collapseNode(child);
            }
          }
        }
        collapseNode(node);
        break;
      default:
        throw UnimplementedError('Action $action is not implemented');
    }
  }

  String? _getPropertyPath(TreeViewNode<JsonTreeData> node) {
    if (node.content.key == null) return null;
    final path = <String>[];
    var currentNode = node;
    while (currentNode.parent != null) {
      if (currentNode.parent?.content is MapTreeData) {
        path.add('[${currentNode.content.key!}]');
      } else {
        path.add(currentNode.content.key!);
      }
      currentNode = currentNode.parent!;
    }
    return path.reversed.join();
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

  bool isSelected(TreeViewNode<JsonTreeData>? node) {
    if (_selectedNode == null || node == null) return false;
    return _selectedNode == node || isSelected(node.parent);
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

  @override
  void dispose() {
    horizontalScrollController.dispose();
    verticalScrollController.dispose();
    super.dispose();
  }
}
