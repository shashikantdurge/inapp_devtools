import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

TwoDimensionalChildBuilderDelegate _textCellDelegate({
  required String text,
  required TextStyle textStyle,
  required EdgeInsetsGeometry padding,
}) {
  return TwoDimensionalChildBuilderDelegate(
    maxXIndex: 0,
    maxYIndex: 0,
    builder: (BuildContext context, ChildVicinity vicinity) {
      if (vicinity.xIndex != 0 || vicinity.yIndex != 0) {
        return null;
      }
      return Padding(
        padding: padding,
        child: Text(text, softWrap: false, style: textStyle),
      );
    },
  );
}

double _measureTextContentHeight(
  BuildContext context, {
  required String text,
  required TextStyle textStyle,
  required EdgeInsetsGeometry padding,
}) {
  final textDirection = Directionality.of(context);
  final resolvedPadding = padding.resolve(textDirection);
  final painter = TextPainter(
    text: TextSpan(text: text, style: textStyle),
    textDirection: textDirection,
  )..layout(maxWidth: double.infinity);
  return painter.height + resolvedPadding.vertical;
}

/// Two-dimensional scroll view for a single [text] cell.
///
/// Height is the content height when it fits within [maxHeight] (or the parent
/// max height constraint). Otherwise height is capped so the viewport scrolls.
class TwoDimensionalTextScrollView extends StatefulWidget {
  const TwoDimensionalTextScrollView({
    super.key,
    required this.text,
    required this.textStyle,
    this.padding = EdgeInsets.zero,
    this.maxHeight = 200,
    this.diagonalDragBehavior = DiagonalDragBehavior.free,
  });

  final String text;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final double maxHeight;
  final DiagonalDragBehavior diagonalDragBehavior;

  @override
  State<TwoDimensionalTextScrollView> createState() =>
      _TwoDimensionalTextScrollViewState();
}

class _TwoDimensionalTextScrollViewState
    extends State<TwoDimensionalTextScrollView> {
  double _contentHeight = 0;
  bool _measuredInDependencies = false;
  ScrollController? _verticalScrollController;
  ScrollController? _horizontalScrollController;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _remeasureContentHeight(scheduleRebuild: _measuredInDependencies);
    _measuredInDependencies = true;
    _verticalScrollController ??= ScrollController();
    _horizontalScrollController ??= ScrollController();
  }

  @override
  void didUpdateWidget(TwoDimensionalTextScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.textStyle != widget.textStyle ||
        oldWidget.padding != widget.padding) {
      _remeasureContentHeight();
    }
  }

  void _remeasureContentHeight({bool scheduleRebuild = true}) {
    final measuredHeight = _measureTextContentHeight(
      context,
      text: widget.text,
      textStyle: widget.textStyle,
      padding: widget.padding,
    );
    if (measuredHeight == _contentHeight) {
      return;
    }
    _contentHeight = measuredHeight;
    if (scheduleRebuild) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _verticalScrollController?.dispose();
    _horizontalScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final heightCap = constraints.maxHeight.isFinite
            ? math.min(constraints.maxHeight, widget.maxHeight)
            : widget.maxHeight;
        final height = math.min(_contentHeight, heightCap);

        return SizedBox(
          width: width,
          height: height,
          child: _TwoDimensionalTextScrollView(
            text: widget.text,
            textStyle: widget.textStyle,
            padding: widget.padding,
            diagonalDragBehavior: widget.diagonalDragBehavior,
          ),
        );
      },
    );
  }
}

class _TwoDimensionalTextScrollView extends TwoDimensionalScrollView {
  _TwoDimensionalTextScrollView({
    required this.text,
    required this.textStyle,
    required this.padding,
    super.diagonalDragBehavior = DiagonalDragBehavior.free,
  }) : super(
         delegate: _textCellDelegate(
           text: text,
           textStyle: textStyle,
           padding: padding,
         ),
       );

  final String text;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return _TwoDimensionalTextViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      mainAxis: mainAxis,
      delegate: delegate,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }
}

class _TwoDimensionalTextViewport extends TwoDimensionalViewport {
  const _TwoDimensionalTextViewport({
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  });

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return _RenderTwoDimensionalTextViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      delegate: delegate,
      childManager: context as TwoDimensionalChildManager,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTwoDimensionalTextViewport renderObject,
  ) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..delegate = delegate
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class _RenderTwoDimensionalTextViewport extends RenderTwoDimensionalViewport {
  _RenderTwoDimensionalTextViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  });

  static const _contentVicinity = ChildVicinity(xIndex: 0, yIndex: 0);

  @override
  void layoutChildSequence() {
    final RenderBox? child = buildOrObtainChildFor(_contentVicinity);
    final double viewportWidth = viewportDimension.width;
    final double viewportHeight = viewportDimension.height;

    if (child == null) {
      horizontalOffset.applyContentDimensions(0.0, 0.0);
      verticalOffset.applyContentDimensions(0.0, 0.0);
      return;
    }

    child.layout(const BoxConstraints(), parentUsesSize: true);

    parentDataOf(child).layoutOffset = Offset(
      -horizontalOffset.pixels,
      -verticalOffset.pixels,
    );

    horizontalOffset.applyContentDimensions(
      0.0,
      math.max(0.0, child.size.width - viewportWidth),
    );
    verticalOffset.applyContentDimensions(
      0.0,
      math.max(0.0, child.size.height - viewportHeight),
    );
  }
}

/// Bordered box that displays arbitrary [text] in a [TwoDimensionalTextScrollView].
class TwoDimensionalTextBox extends StatelessWidget {
  const TwoDimensionalTextBox({
    super.key,
    required this.text,
    this.textStyle,
    this.padding = const EdgeInsets.all(10),
    this.maxHeight = 200,
    this.backgroundColor = const Color(0xFF141414),
    this.borderColor = Colors.transparent,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.diagonalDragBehavior = DiagonalDragBehavior.free,
  });

  static const _defaultTextStyle = TextStyle(
    fontSize: 12,
    height: 1.35,
    fontFamily: 'monospace',
    color: Color(0xFFBDBDBD),
  );

  final String text;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double maxHeight;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final DiagonalDragBehavior diagonalDragBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: borderRadius,
      ),
      child: TwoDimensionalTextScrollView(
        text: text,
        textStyle: textStyle ?? _defaultTextStyle,
        padding: padding,
        maxHeight: maxHeight,
        diagonalDragBehavior: diagonalDragBehavior,
      ),
    );
  }
}
