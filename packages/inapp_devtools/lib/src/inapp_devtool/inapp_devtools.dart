/// In-app devtools overlay: a draggable panel with multiple tools, each with a
/// standard app bar and body ([InAppDevToolsScaffold] + [InAppDevToolsAppBar]).
///
/// Use [InAppDevTools.of] / [InAppDevTools.panelModeOf] from
/// descendants to read [InAppDevToolsController] and drive [InAppDevToolsPanelWindowMode].
library;

import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:inapp_devtools/src/inapp_devtool/inapp_devtool_network.dart';
import 'package:inapp_devtools/src/network_tool/http_profiler.dart'
    show HttpProfiler;
import 'package:inapp_devtools/src/network_tool/iad_clients/iad_http_client.dart'
    show IADNetworkHttpOverrides;

import 'inapp_devtools_theme.dart';

/// A mixin for widgets which can be used as a tool in the in-app devtools [InAppDevTools.tools].
///
/// Eg.
/// ```dart
/// class CustomToolWidget extends StatefulWidget implements InAppDevToolsItem {
///   const CustomToolWidget({super.key});
///
///   @override
///   State<CustomToolWidget> createState() => CustomToolWidgetState();
///
///   @override
///   String get label => 'My Custom Tool';
/// }
/// ```
mixin InAppDevToolsItem on Widget {
  String get label;
  Widget? get labelWidget => null;
}

/// Defines the different window states of the in-app devtools panel.
/// Similar to window modes in desktop.
enum InAppDevToolsPanelWindowMode {
  /// Tool is hidden, but a small button is visible to open it.
  minimized,

  /// Tool is visible partially
  windowed,

  /// Tool is visible at maximum size
  maximized,
}

/// Hosts the in-app devtools overlay and exposes [InAppDevToolsController] via
/// [of] / [panelModeOf].
class InAppDevTools extends StatefulWidget {
  InAppDevTools({
    super.key,
    this.tools = const [InAppDevtoolNetwork()],
    this.initialSelectedToolIndex = 0,
    this.theme,
    this.color,
    this.child,
  }) : assert(tools.isNotEmpty, 'tools must not be empty'),
       assert(
         initialSelectedToolIndex >= 0 &&
             initialSelectedToolIndex < tools.length,
         'initialSelectedToolIndex must be between 0 and tools.length - 1',
       );

  /// Registered tools (tabs); order matches horizontal picker indices.
  final List<InAppDevToolsItem> tools;

  /// Index into [tools] shown when the panel is not collapsed.
  final int initialSelectedToolIndex;

  /// Overrides default chrome from [InAppDevToolsThemeData.dark].
  final InAppDevToolsThemeData? theme;

  /// Optional accent for minimized FAB and panel outline; defaults come from [theme].
  final Color? color;

  final Widget? child;

  /// DevTools controller from the nearest [InAppDevTools] ancestor.
  static InAppDevToolsController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InAppDevToolsScope>()!
        .notifier!;
  }

  /// Current [InAppDevToolsPanelWindowMode] from the nearest [InAppDevTools].
  static InAppDevToolsPanelWindowMode panelModeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InAppDevToolsScope>()!
        .notifier!
        .panelMode;
  }

  static void ensureInitialized() {
    // Initialize the network tools
    HttpProfiler.ensureInitialized();
    HttpOverrides.global = IADNetworkHttpOverrides();
  }

  @override
  State<InAppDevTools> createState() => _InAppDevToolsState();
}

class _InAppDevToolsState extends State<InAppDevTools> {
  late final InAppDevToolsController _controller = InAppDevToolsController();

  @override
  void initState() {
    super.initState();
    InAppDevTools.ensureInitialized();
    _controller
      ..setTools(widget.tools)
      ..setSelectedToolIndex(widget.initialSelectedToolIndex);
  }

  @override
  void didUpdateWidget(covariant InAppDevTools oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DeepCollectionEquality().equals(oldWidget.tools, widget.tools)) {
      _controller.setTools(widget.tools);
    }
  }

  Widget _buildPanelContent(BuildContext context) {
    final chrome = InAppDevToolsTheme.of(context);
    final mode = _controller.panelMode;
    final selectedTool = _controller.tools[_controller.selectedToolIndex];
    switch (mode) {
      case InAppDevToolsPanelWindowMode.minimized:
        return GestureDetector(
          onTap: () {
            _controller.setPanelMode(InAppDevToolsPanelWindowMode.windowed);
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color ?? chrome.minimizedFabBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.developer_mode,
              color: chrome.minimizedFabIconColor,
            ),
          ),
        );
      case InAppDevToolsPanelWindowMode.windowed:
      case InAppDevToolsPanelWindowMode.maximized:
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.color ?? chrome.panelBorderColor,
              width: 2,
            ),
          ),
          child: selectedTool,
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppDevToolsTheme(
      data: widget.theme ?? InAppDevToolsThemeData.dark,
      child: Builder(
        builder: (context) {
          final devPanel = SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _InAppDevToolsScope(
                  notifier: _controller,
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, child) {
                      return _InAppDevToolsDraggablePanel(
                        maxSize: constraints.biggest,
                        panelMode: _controller.panelMode,
                        child: Material(
                          type: MaterialType.transparency,
                          child: _buildPanelContent(context),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
          return Stack(
            children: [
              if (widget.child != null) Positioned.fill(child: widget.child!),
              devPanel,
            ],
          );
        },
      ),
    );
  }
}

// --- Draggable floating panel -----------------------------------------------

class _InAppDevToolsDraggablePanel extends StatefulWidget {
  const _InAppDevToolsDraggablePanel({
    required this.maxSize,
    required this.child,
    required this.panelMode,
  });

  final Size maxSize;
  final Widget child;
  final InAppDevToolsPanelWindowMode panelMode;

  Map<InAppDevToolsPanelWindowMode, Size> get _sizeByMode => {
    .minimized: const Size(56.0, 56.0),
    .windowed: Size(maxSize.width, maxSize.height / 3),
    .maximized: maxSize,
  };

  @override
  State<_InAppDevToolsDraggablePanel> createState() =>
      _InAppDevToolsDraggablePanelState();
}

class _InAppDevToolsDraggablePanelState
    extends State<_InAppDevToolsDraggablePanel>
    with SingleTickerProviderStateMixin {
  static const double _friction = 0.95;
  static const double _velocityScale = 0.5;
  static const double _stopThreshold = 10.0;

  /// Last [Offset] for each [InAppDevToolsPanelWindowMode] so resize preserves rough position.
  final Map<InAppDevToolsPanelWindowMode, Offset> _positionByMode = {
    .minimized: const Offset(100, 100),
    .windowed: const Offset(100, 100),
    .maximized: const Offset(100, 100),
  };

  late Size _panelSize;
  late double _left;
  late double _top;
  Offset _velocity = Offset.zero;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  double get _panelWidth => _panelSize.width;
  double get _panelHeight => _panelSize.height;

  @override
  void initState() {
    super.initState();
    _left = 100;
    _top = 100;
    _panelSize = widget._sizeByMode[widget.panelMode]!;
  }

  @override
  void didUpdateWidget(_InAppDevToolsDraggablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maxSize != oldWidget.maxSize ||
        oldWidget.panelMode != widget.panelMode) {
      _panelSize = widget._sizeByMode[widget.panelMode]!;
    }
    if (oldWidget.panelMode != widget.panelMode) {
      _positionByMode[oldWidget.panelMode] = Offset(_left, _top);
      _left = _positionByMode[widget.panelMode]!.dx;
      if (widget.panelMode != InAppDevToolsPanelWindowMode.maximized &&
          oldWidget.panelMode == InAppDevToolsPanelWindowMode.maximized) {
        _top = _positionByMode[widget.panelMode]!.dy;
      }
      _clampPosition();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _clampPosition() {
    final oldLeft = _left;
    final oldTop = _top;

    _left = _left.clamp(0.0, widget.maxSize.width - _panelWidth);
    _top = _top.clamp(0.0, widget.maxSize.height - _panelHeight);

    if (_left != oldLeft) {
      _velocity = Offset(0, _velocity.dy);
    }
    if (_top != oldTop) {
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
        _left += _velocity.dx * dt;
        _top += _velocity.dy * dt;

        _clampPosition();

        _velocity = Offset(
          _velocity.dx * pow(_friction, dt * 60),
          _velocity.dy * pow(_friction, dt * 60),
        );

        if (_velocity.distance < _stopThreshold) {
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
      _left += details.delta.dx;
      _top += details.delta.dy;
      _clampPosition();
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _velocity = details.velocity.pixelsPerSecond * _velocityScale;
      if (_velocity.distance > _stopThreshold) {
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
    if (_left > widget.maxSize.width - _panelWidth) {
      _left = widget.maxSize.width - _panelWidth;
    }
    if (_top > widget.maxSize.height - _panelHeight) {
      _top = widget.maxSize.height - _panelHeight;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: _left,
          top: _top,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanCancel: _onPanCancel,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: _panelWidth,
              height: _panelHeight,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

// --- Inherited scope + controller -------------------------------------------

class _InAppDevToolsScope extends InheritedNotifier<InAppDevToolsController> {
  const _InAppDevToolsScope({required super.notifier, required super.child});

  @override
  bool updateShouldNotify(
    InheritedNotifier<InAppDevToolsController> oldWidget,
  ) {
    return oldWidget.notifier != notifier;
  }
}

/// Mutable devtools state: [panelMode], [tools], and [selectedToolIndex].
///
/// Obtained with [InAppDevTools.of]; do not construct for the root widget
/// (that is owned by [InAppDevTools]).
class InAppDevToolsController extends ChangeNotifier {
  InAppDevToolsPanelWindowMode _panelMode = .minimized;
  int _selectedToolIndex = 0;
  List<InAppDevToolsItem> _tools = [];

  InAppDevToolsPanelWindowMode get panelMode => _panelMode;

  int get selectedToolIndex => _selectedToolIndex;

  List<InAppDevToolsItem> get tools => List.unmodifiable(_tools);

  /// Replaces the tool list and clamps [selectedToolIndex] to a valid range.
  void setTools(List<InAppDevToolsItem> tools) {
    _tools = tools;
    if (_tools.isEmpty) {
      _selectedToolIndex = 0;
    } else {
      _selectedToolIndex = _selectedToolIndex.clamp(0, _tools.length - 1);
    }
    notifyListeners();
  }

  void setPanelMode(InAppDevToolsPanelWindowMode mode) {
    _panelMode = mode;
    notifyListeners();
  }

  void setSelectedToolIndex(int index) {
    _selectedToolIndex = index;
    notifyListeners();
  }

  void toggleWindowState() {
    switch (_panelMode) {
      case InAppDevToolsPanelWindowMode.windowed:
        _panelMode = InAppDevToolsPanelWindowMode.maximized;
        break;
      case InAppDevToolsPanelWindowMode.maximized:
        _panelMode = InAppDevToolsPanelWindowMode.windowed;
        break;
      case InAppDevToolsPanelWindowMode.minimized:
        break;
    }
  }
}
