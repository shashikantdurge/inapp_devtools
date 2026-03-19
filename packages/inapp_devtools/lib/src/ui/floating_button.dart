import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FloatingButton extends StatefulWidget {
  const FloatingButton({
    super.key,
    required this.maxWidth,
    required this.maxHeight,
    required this.child,
    this.size = const Size(56.0, 56.0),
  });
  final double maxWidth;
  final double maxHeight;
  final Widget child;
  final Size size;
  @override
  State<FloatingButton> createState() => _FloatingButtonState();
}

class _FloatingButtonState extends State<FloatingButton>
    with SingleTickerProviderStateMixin {
  static const double friction = 0.95;
  static const double velocityScale = 0.5;
  static const double stopThreshold = 10.0;

  late double _x;
  late double _y;
  Offset _velocity = Offset.zero;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  double get _buttonWidth => widget.size.width;
  double get _buttonHeight => widget.size.height;

  @override
  void initState() {
    super.initState();
    _x = 100;
    _y = 100;
  }

  @override
  void didUpdateWidget(FloatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size) {
      _clampPosition();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _clampPosition() {
    final oldX = _x;
    final oldY = _y;

    _x = _x.clamp(0.0, widget.maxWidth - _buttonWidth);
    _y = _y.clamp(0.0, widget.maxHeight - _buttonHeight);

    if (_x != oldX) {
      _velocity = Offset(0, _velocity.dy);
    }
    if (_y != oldY) {
      _velocity = Offset(_velocity.dx, 0);
    }
  }

  void _startPhysics() {
    if (_ticker?.isActive ?? false) return;
    _lastElapsed = Duration.zero;
    _ticker ??= createTicker((elapsed) {
      final dt = _lastElapsed == Duration.zero
          ? 0.016
          : (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      setState(() {
        _x += _velocity.dx * dt;
        _y += _velocity.dy * dt;

        _clampPosition();

        _velocity = Offset(
          _velocity.dx * pow(friction, dt * 60),
          _velocity.dy * pow(friction, dt * 60),
        );

        if (_velocity.distance < stopThreshold) {
          _velocity = Offset.zero;
          _ticker?.stop();
        }
      });
    });
    _ticker!.start();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _velocity = Offset.zero;
      _ticker?.stop();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;
      _clampPosition();
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _velocity = details.velocity.pixelsPerSecond * velocityScale;
      if (_velocity.distance > stopThreshold) {
        _startPhysics();
      }
    });
  }

  void _onPanCancel() {
    setState(() {
      _velocity = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_x > widget.maxWidth - _buttonWidth) {
      _x = widget.maxWidth - _buttonWidth;
    }
    if (_y > widget.maxHeight - _buttonHeight) {
      _y = widget.maxHeight - _buttonHeight;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: _x,
          top: _y,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanCancel: _onPanCancel,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: _buttonWidth,
              height: _buttonHeight,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
