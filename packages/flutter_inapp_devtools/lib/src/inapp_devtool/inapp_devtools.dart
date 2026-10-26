/// In-app devtools overlay: draggable panel, tool picker, and shared chrome.
library;

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../analytics_tool/analytics_tool.dart';
import '../logging_tool/logging_tool.dart';
import '../network_tool/network_tool.dart';
import 'theme.dart';

/// A mixin for widgets which can be used as a tool in the in-app devtools [InAppDevTools.tools].
///
/// Eg.
/// ```dart
/// class CustomToolWidget extends StatefulWidget with InAppDevToolsItem {
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
  void initTool() {}
  void disposeTool() {}
}

typedef CopyDataCallback = void Function(Object data);

void _defaultCopyDataCallback(Object data) {
  debugPrint('$data');
  Clipboard.setData(ClipboardData(text: data.toString()));
}

/// How much of the screen the devtools overlay occupies.
enum InAppDevToolsPanelWindowMode {
  /// Only the floating action button is shown; tap it to open the panel.
  minimized,

  /// The panel uses roughly one third of the available height.
  windowed,

  /// The panel fills the safe area.
  maximized,
}

/// Root widget that overlays in-app developer tools on top of your application.
///
/// * [tools] - List of tools to display in the devtools overlay.
/// * [initialSelectedToolIndex] - Index of the tool to select when the panel is opened.
/// * [theme] - Theme for the devtools overlay.
/// * [color] - Color for the devtools overlay.
/// * [child] - The application rendered underneath the devtools overlay.
///
/// # Usage
///
/// ```dart
/// void main() {
///   runApp(
///     InAppDevTools(
///       child: MaterialApp(
///         home: MyHomePage(),
///       ),
///     ),
///   );
/// }
/// ```
///
/// See also:
/// * [InAppDevToolsItem] — contract for [tools] entries.
/// * [NetworkTool] - Logs network calls
/// * [LoggingTool] - Logs [Logger] records
/// * [AnalyticsTool] - Logs analytics events
class InAppDevTools extends StatefulWidget {
  /// Creates a devtools host that overlays [child].
  ///
  /// [tools] must contain at least one [InAppDevToolsItem].
  /// [initialSelectedToolIndex] must be in `0 .. tools.length - 1`.
  InAppDevTools({
    super.key,
    this.tools = const [NetworkTool(), AnalyticsTool(), LoggingTool()],
    this.initialSelectedToolIndex = 0,
    this.theme,
    this.color,
    this.child,
    this.copyDataCallback,
  }) : assert(tools.isNotEmpty, 'tools must not be empty'),
       assert(
         initialSelectedToolIndex >= 0 &&
             initialSelectedToolIndex < tools.length,
         'initialSelectedToolIndex must be between 0 and tools.length - 1',
       );

  /// DevTools panels registered with this host, in tab order.
  final List<InAppDevToolsItem> tools;

  /// Which [tools] entry is selected when the panel is first opened.
  final int initialSelectedToolIndex;

  /// Visual theme for the overlay; defaults to [InAppDevToolsThemeData.dark].
  final InAppDevToolsThemeData? theme;

  /// Accent color for the minimized FAB and panel border when [theme] does not
  /// specify them.
  final Color? color;

  /// The application rendered underneath the devtools overlay.
  final Widget? child;

  /// Customise the copy data behaviour.
  final CopyDataCallback? copyDataCallback;

  /// The [InAppDevToolsController] for the nearest [InAppDevTools] ancestor.
  ///
  /// Use this to read or update [InAppDevToolsController.panelMode] and
  /// [InAppDevToolsController.selectedToolIndex]. The returned controller
  /// is a [Listenable]; wrap UI in [ListenableBuilder] or listen in
  /// [State] when reacting to changes.
  ///
  /// Must be called from a context below [InAppDevTools] (for example inside
  /// a tool widget built as a child of this host).
  ///
  /// It's rare to use this directly.
  static InAppDevToolsController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InAppDevToolsControllerProvider>()!
        .notifier!;
  }

  /// Shared per-overlay state store for tool widgets.
  ///
  /// Keys are [Type] values; use [ToolStateNotifier.set] and
  /// [ToolStateNotifier.get] from tool code. Prefer this over static globals
  /// when state should persist across tab switches but not across app restarts.
  static ToolStateNotifier toolStateNotifier(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ToolStateProvider>()!
        .notifier!;
  }

  @override
  State<InAppDevTools> createState() => _InAppDevToolsState();
}

class _InAppDevToolsState extends State<InAppDevTools> {
  late final InAppDevToolsController _controller = InAppDevToolsController();
  late final ToolStateNotifier _toolsState = ToolStateNotifier();

  @override
  void initState() {
    super.initState();
    _controller
      ..setTools(widget.tools)
      ..setSelectedToolIndex(widget.initialSelectedToolIndex)
      ..setCopyDataCallback(
        widget.copyDataCallback ?? _defaultCopyDataCallback,
      );
    _initTools();
  }

  void _initTools() {
    for (final tool in widget.tools) {
      tool.initTool();
    }
  }

  void _disposeTools() {
    for (final tool in widget.tools) {
      tool.disposeTool();
    }
  }

  /// Updates the initialized and disposed state of tools when the tool list changes.
  /// Initializes any new tools that were not present in the previous list,
  /// and disposes any tools from the old list that are no longer present in the new list.
  void _updateTools({
    required List<InAppDevToolsItem> oldTools,
    required List<InAppDevToolsItem> newTools,
  }) {
    // Find new tools that need to be initialized (not present in oldTools by key and runtimeType).
    final uninitializedNewTools = newTools.where((newTool) {
      return !oldTools.any(
        (oldTool) =>
            oldTool.runtimeType == newTool.runtimeType &&
            oldTool.key == newTool.key,
      );
    });

    // Find old tools that need to be disposed (not present in newTools by key and runtimeType).
    final toolsToDispose = oldTools.where((oldTool) {
      return !newTools.any(
        (newTool) =>
            newTool.runtimeType == oldTool.runtimeType &&
            newTool.key == oldTool.key,
      );
    });

    // Dispose old tools no longer present.
    for (final tool in toolsToDispose) {
      tool.disposeTool();
    }

    // Initialize new tools newly added.
    for (final tool in uninitializedNewTools) {
      tool.initTool();
    }
  }

  @override
  void didUpdateWidget(covariant InAppDevTools oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DeepCollectionEquality().equals(oldWidget.tools, widget.tools)) {
      _controller.setTools(widget.tools);
    }
    _updateTools(oldTools: oldWidget.tools, newTools: widget.tools);
    if (widget.copyDataCallback != oldWidget.copyDataCallback) {
      _controller.setCopyDataCallback(
        widget.copyDataCallback ?? _defaultCopyDataCallback,
      );
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
        return Container(
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
    _disposeTools();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppDevToolsTheme(
      data: widget.theme ?? InAppDevToolsThemeData.dark,
      child: Builder(
        builder: (context) {
          final devPanel = SafeArea(
            maintainBottomViewPadding: true,
            child: _ToolStateProvider(
              notifier: _toolsState,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _InAppDevToolsControllerProvider(
                    notifier: _controller,
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, child) {
                        return _InAppDevToolsDraggablePanel(
                          maxSize: constraints.biggest,
                          panelMode: _controller.panelMode,
                          child: MaterialApp(
                            debugShowCheckedModeBanner: false,
                            onNavigationNotification: (_) => false,
                            home: _buildPanelContent(context),
                            theme: getDakTheme(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
          return Stack(
            textDirection: TextDirection.ltr,
            children: [
              if (widget.child != null) Positioned.fill(child: widget.child!),
              Theme(
                data: getDakTheme(),
                child: Localizations(
                  locale: Locale('en'),
                  delegates: [
                    DefaultMaterialLocalizations.delegate,
                    DefaultWidgetsLocalizations.delegate,
                  ],
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: devPanel,
                  ),
                ),
              ),
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
    _clampPosition();
  }

  @override
  void didUpdateWidget(_InAppDevToolsDraggablePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maxSize != oldWidget.maxSize ||
        oldWidget.panelMode != widget.panelMode) {
      _panelSize = widget._sizeByMode[widget.panelMode]!;
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

class _InAppDevToolsControllerProvider
    extends InheritedNotifier<InAppDevToolsController> {
  const _InAppDevToolsControllerProvider({
    required super.notifier,
    required super.child,
  });

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
  CopyDataCallback _copyDataCallback = _defaultCopyDataCallback;

  CopyDataCallback get copyDataCallback => _copyDataCallback;

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

  void setCopyDataCallback(CopyDataCallback copyData) {
    _copyDataCallback = copyData;
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

/// Provides a [ToolStateNotifier] scoped to the devtools overlay.
class _ToolStateProvider extends InheritedNotifier<ToolStateNotifier> {
  const _ToolStateProvider({required super.notifier, required super.child});

  @override
  bool updateShouldNotify(InheritedNotifier<Listenable> oldWidget) {
    return oldWidget.notifier != notifier;
  }
}

/// Typed key–value store scoped to one [InAppDevTools] overlay.
///
/// Obtained via [InAppDevTools.toolStateNotifier]. Notifies listeners when
/// [set] is called with `notify: true` (the default).
class ToolStateNotifier extends ChangeNotifier {
  final Map<Type, Object?> _state = {};

  /// Whether a value has been stored for type [T].
  bool has<T>() {
    return _state.containsKey(T);
  }

  /// Returns the value for type [T], or `null` if none was [set].
  T? get<T>() {
    return _state[T] as T?;
  }

  /// Stores [value] under the key [T]. Pass `null` only when [T] is nullable.
  void set<T>(T? value, {bool notify = true}) {
    assert(
      (T != Null && value == null) || value != null,
      'T should be provided when value is null',
    );
    _state[T] = value;
    if (notify) {
      notifyListeners();
    }
  }
}
