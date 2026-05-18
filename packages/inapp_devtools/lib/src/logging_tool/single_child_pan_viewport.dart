import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Scroll bounds for [clampSingleChildPanOffset].
({double minX, double maxX, double minY, double maxY})
singleChildPanOffsetBounds({
  required Size viewportSize,
  required Size childSize,
}) {
  return (
    minX: math.min(0.0, viewportSize.width - childSize.width),
    maxX: math.max(0.0, viewportSize.width - childSize.width),
    minY: math.min(0.0, viewportSize.height - childSize.height),
    maxY: math.max(0.0, viewportSize.height - childSize.height),
  );
}

/// Clamps [offset] so [childSize] cannot be panned past the edges of
/// [viewportSize] (no empty space beyond the child).
Offset clampSingleChildPanOffset(
  Offset offset, {
  required Size viewportSize,
  required Size childSize,
}) {
  final bounds = singleChildPanOffsetBounds(
    viewportSize: viewportSize,
    childSize: childSize,
  );
  return Offset(
    offset.dx.clamp(bounds.minX, bounds.maxX),
    offset.dy.clamp(bounds.minY, bounds.maxY),
  );
}

/// Whether the [childSize] exceeds the parent-constrained [viewportSize] on
/// either axis (i.e. panning can do anything).
bool singleChildPanNeedsPan({
  required Size viewportSize,
  required Size childSize,
}) {
  return childSize.width > viewportSize.width ||
      childSize.height > viewportSize.height;
}

class _InteractiveScrollMetrics {
  _InteractiveScrollMetrics({
    required this.viewportSize,
    required this.childSize,
    required this.offset,
    required this.devicePixelRatio,
  });

  final Size viewportSize;
  final Size childSize;
  final Offset offset;
  final double devicePixelRatio;

  ({double minX, double maxX, double minY, double maxY}) get bounds =>
      singleChildPanOffsetBounds(
        viewportSize: viewportSize,
        childSize: childSize,
      );

  FixedScrollMetrics _axisMetrics({
    required double pixels,
    required double minScrollExtent,
    required double maxScrollExtent,
    required double viewportDimension,
    required AxisDirection axisDirection,
  }) {
    return FixedScrollMetrics(
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
      pixels: pixels,
      viewportDimension: viewportDimension,
      axisDirection: axisDirection,
      devicePixelRatio: devicePixelRatio,
    );
  }

  FixedScrollMetrics get horizontal {
    final b = bounds;
    return _axisMetrics(
      pixels: offset.dx,
      minScrollExtent: b.minX,
      maxScrollExtent: b.maxX,
      viewportDimension: viewportSize.width,
      axisDirection: AxisDirection.right,
    );
  }

  FixedScrollMetrics get vertical {
    final b = bounds;
    return _axisMetrics(
      pixels: offset.dy,
      minScrollExtent: b.minY,
      maxScrollExtent: b.maxY,
      viewportDimension: viewportSize.height,
      axisDirection: AxisDirection.down,
    );
  }
}

/// Accepts the [GestureArena] on pointer down when the child overflows the
/// viewport; otherwise rejects so ancestor scrollables can handle the drag.
class _WinningPanGestureRecognizer extends PanGestureRecognizer {
  bool Function()? shouldRejectPan;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(
      (shouldRejectPan?.call() ?? false)
          ? GestureDisposition.rejected
          : GestureDisposition.accepted,
    );
  }
}

/// A viewport that lays out a single [child] with unconstrained dimensions and
/// pans it in response to drag gestures.
///
/// The child is laid out with unconstrained dimensions. This widget's size is
/// the child's size when smaller than the parent constraint, otherwise the
/// maximum allowed constraint (for panning overflow).
///
/// [physics] controls drag resistance at edges. On release, velocity is animated
/// to zero via a ballistic simulation; offsets past the clamp bounds spring back
/// with a bounce (defaults to [BouncingScrollPhysics]).
///
/// Pan gestures are rejected when the child fits within the viewport, allowing
/// parent scrollables to receive the drag instead.
class SingleChildPanViewport extends StatefulWidget {
  const SingleChildPanViewport({
    super.key,
    required this.child,
    this.physics,
    this.padding = EdgeInsets.zero,
    this.clipBehavior = Clip.hardEdge,
  });

  final Widget child;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  @override
  State<SingleChildPanViewport> createState() =>
      _SingleChildPanViewportState();
}

class _SingleChildPanViewportState extends State<SingleChildPanViewport>
    with TickerProviderStateMixin {
  final GlobalKey _viewportKey = GlobalKey();
  Offset _offset = Offset.zero;
  AnimationController? _animationControllerX;
  AnimationController? _animationControllerY;
  int _activeBallisticAnimations = 0;

  ScrollPhysics get _physics => widget.physics ?? const BouncingScrollPhysics();

  _InteractiveScrollMetrics? _scrollMetrics() {
    final renderObject = _viewportKey.currentContext?.findRenderObject();
    if (renderObject case final RenderSingleChildPanViewport viewport
        when viewport.hasSize && viewport.child != null) {
      return _InteractiveScrollMetrics(
        viewportSize: viewport.size,
        childSize: viewport.child!.size,
        offset: _offset,
        devicePixelRatio: View.of(context).devicePixelRatio,
      );
    }
    return null;
  }

  void _setOffset(Offset next, {bool clamp = false}) {
    final metrics = _scrollMetrics();
    if (metrics != null && clamp) {
      next = clampSingleChildPanOffset(
        next,
        viewportSize: metrics.viewportSize,
        childSize: metrics.childSize,
      );
    }
    if (next == _offset) {
      return;
    }
    setState(() => _offset = next);
  }

  void _stopBallistic() {
    _activeBallisticAnimations = 0;
    _animationControllerX?.dispose();
    _animationControllerX = null;
    _animationControllerY?.dispose();
    _animationControllerY = null;
  }

  void _onBallisticAnimationTick() {
    _setOffset(
      Offset(
        _animationControllerX?.value ?? _offset.dx,
        _animationControllerY?.value ?? _offset.dy,
      ),
    );
  }

  void _onBallisticAnimationEnd() {
    _activeBallisticAnimations--;
    if (_activeBallisticAnimations > 0) {
      return;
    }
    _stopBallistic();
    // Keep the simulation's final position (do not snap back to finger-up offset).
    _setOffset(_offset, clamp: true);
  }

  Simulation? _simulationForAxis({
    required FixedScrollMetrics metrics,
    required double velocity,
  }) {
    final ScrollPhysics physics = _physics;
    final Tolerance tolerance = physics.toleranceFor(metrics);
    final bool hasVelocity = velocity.abs() >= tolerance.velocity;
    final bool outOfRange = metrics.outOfRange;

    if (!hasVelocity && !outOfRange) {
      return null;
    }

    if (metrics.maxScrollExtent <= metrics.minScrollExtent) {
      if (!outOfRange) {
        return null;
      }
      final double target = metrics.pixels.clamp(
        metrics.minScrollExtent,
        metrics.maxScrollExtent,
      );
      return ScrollSpringSimulation(
        physics.spring,
        metrics.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }

    if (physics case BouncingScrollPhysics bouncing) {
      return BouncingScrollSimulation(
        spring: bouncing.spring,
        position: metrics.pixels,
        velocity: velocity,
        leadingExtent: metrics.minScrollExtent,
        trailingExtent: metrics.maxScrollExtent,
        tolerance: tolerance,
        constantDeceleration: switch (bouncing.decelerationRate) {
          ScrollDecelerationRate.fast => 1400,
          ScrollDecelerationRate.normal => 0,
        },
      );
    }

    if (outOfRange) {
      final double target = metrics.pixels.clamp(
        metrics.minScrollExtent,
        metrics.maxScrollExtent,
      );
      return ScrollSpringSimulation(
        physics.spring,
        metrics.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }

    return physics.createBallisticSimulation(metrics, velocity);
  }

  void _startBallisticAnimation({
    required Simulation simulation,
    required bool horizontal,
  }) {
    _activeBallisticAnimations++;
    final controller = AnimationController.unbounded(vsync: this)
      ..addListener(_onBallisticAnimationTick);

    if (horizontal) {
      _animationControllerX = controller;
    } else {
      _animationControllerY = controller;
    }

    controller.animateWith(simulation).whenComplete(() {
      controller.removeListener(_onBallisticAnimationTick);
      if (horizontal) {
        _animationControllerX = null;
      } else {
        _animationControllerY = null;
      }
      controller.dispose();
      _onBallisticAnimationEnd();
    });
  }

  @override
  void dispose() {
    _stopBallistic();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    _stopBallistic();
  }

  double _applyPhysicsToUserOffset(FixedScrollMetrics metrics, double delta) {
    if (delta == 0.0) {
      return 0.0;
    }
    return _physics.applyPhysicsToUserOffset(metrics, delta);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final metrics = _scrollMetrics();
    if (metrics == null) {
      _setOffset(_offset + details.delta);
      return;
    }
    _setOffset(
      Offset(
        _offset.dx +
            _applyPhysicsToUserOffset(metrics.horizontal, details.delta.dx),
        _offset.dy +
            _applyPhysicsToUserOffset(metrics.vertical, details.delta.dy),
      ),
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    final metrics = _scrollMetrics();
    if (metrics == null) {
      return;
    }
    _stopBallistic();

    final clamped = clampSingleChildPanOffset(
      _offset,
      viewportSize: metrics.viewportSize,
      childSize: metrics.childSize,
    );

    final velocity = details.velocity.pixelsPerSecond;

    final Simulation? simulationX = _simulationForAxis(
      metrics: metrics.horizontal,
      velocity: velocity.dx,
    );
    final Simulation? simulationY = _simulationForAxis(
      metrics: metrics.vertical,
      velocity: velocity.dy,
    );

    if (simulationX == null && simulationY == null) {
      _setOffset(clamped, clamp: true);
      return;
    }

    if (simulationX case final Simulation simulation) {
      _startBallisticAnimation(simulation: simulation, horizontal: true);
    }
    if (simulationY case final Simulation simulation) {
      _startBallisticAnimation(simulation: simulation, horizontal: false);
    }
  }

  void _handlePanCancel() {
    _stopBallistic();
    _setOffset(_offset, clamp: true);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        _WinningPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_WinningPanGestureRecognizer>(
              _WinningPanGestureRecognizer.new,
              (_WinningPanGestureRecognizer instance) {
                instance
                  ..onStart = _handlePanStart
                  ..onUpdate = _handlePanUpdate
                  ..onEnd = _handlePanEnd
                  ..onCancel = _handlePanCancel
                  ..shouldRejectPan = () {
                    final renderObject = _viewportKey.currentContext
                        ?.findRenderObject();
                    if (renderObject
                        case final RenderSingleChildPanViewport viewport
                        when viewport.hasSize && viewport.child != null) {
                      return !singleChildPanNeedsPan(
                        viewportSize: viewport.size,
                        childSize: viewport.child!.size,
                      );
                    }
                    return false;
                  };
              },
            ),
      },
      child: _SingleChildPanViewport(
        key: _viewportKey,
        offset: _offset,
        clipBehavior: widget.clipBehavior,
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );
  }
}

class _SingleChildPanViewport extends SingleChildRenderObjectWidget {
  const _SingleChildPanViewport({
    super.key,
    required this.offset,
    required this.clipBehavior,
    super.child,
  });

  final Offset offset;
  final Clip clipBehavior;

  @override
  RenderSingleChildPanViewport createRenderObject(
    BuildContext context,
  ) {
    return RenderSingleChildPanViewport(
      offset: offset,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSingleChildPanViewport renderObject,
  ) {
    renderObject
      ..offset = offset
      ..clipBehavior = clipBehavior;
  }
}

class RenderSingleChildPanViewport extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  RenderSingleChildPanViewport({
    required Offset offset,
    Clip clipBehavior = Clip.hardEdge,
  }) : _offset = offset,
       _clipBehavior = clipBehavior;

  Offset _offset;
  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset == value) {
      return;
    }
    _offset = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  Clip _clipBehavior;
  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (_clipBehavior == value) {
      return;
    }
    _clipBehavior = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    if (child == null) {
      size = constraints.constrain(constraints.smallest);
      return;
    }

    child.layout(const BoxConstraints(), parentUsesSize: true);

    final Size maxSize = constraints.constrain(constraints.biggest);
    size = constraints.constrain(
      Size(
        math.min(child.size.width, maxSize.width),
        math.min(child.size.height, maxSize.height),
      ),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return child?.getMinIntrinsicWidth(height) ?? 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return child?.getMaxIntrinsicWidth(height) ?? 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return child?.getMinIntrinsicHeight(width) ?? 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return child?.getMaxIntrinsicHeight(width) ?? 0.0;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }

    if (_clipBehavior == Clip.none) {
      context.paintChild(child, offset + _offset);
      return;
    }

    context.pushClipRect(needsCompositing, offset, Offset.zero & size, (
      PaintingContext context,
      Offset offset,
    ) {
      context.paintChild(child, offset + _offset);
    }, clipBehavior: _clipBehavior);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? child = this.child;
    if (child == null) {
      return false;
    }

    return result.addWithPaintOffset(
      offset: _offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!(Offset.zero & size).contains(position)) {
      return false;
    }
    return hitTestChildren(result, position: position) || hitTestSelf(position);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool get isRepaintBoundary => true;
}
