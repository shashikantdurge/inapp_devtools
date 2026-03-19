import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:inapp_devtools/src/core/network_tool/network_tool_http_overrides.dart';

class InAppDevtoolsWidget extends StatefulWidget {
  const InAppDevtoolsWidget({required this.child, this.networkTool, super.key});
  final Widget child;
  final NetworkToolWidget? networkTool;
  @override
  State<InAppDevtoolsWidget> createState() => _InAppDevtoolsWidgetState();
}

class _InAppDevtoolsWidgetState extends State<InAppDevtoolsWidget>
    with InAppNetworkToolStateMixin<InAppDevtoolsWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(child: widget.child),
        Positioned.fill(
          child: WidgetsApp(
            color: Colors.blue,
            builder: (context, child) {
              return DevToolWidget();
            },
          ),
        ),
      ],
    );
  }
}

class DevToolWidget extends StatefulWidget {
  const DevToolWidget({super.key});

  @override
  State<DevToolWidget> createState() => _DevToolWidgetState();
}

class _DevToolWidgetState extends State<DevToolWidget> {
  DevtoolUiState _uiState = DevtoolUiState.collapsed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget child = switch (_uiState) {
          DevtoolUiState.collapsed => GestureDetector(
            onTap: () {
              setState(() {
                _uiState = DevtoolUiState.expanded;
              });
            },
            child: Material(
              color: Colors.blue,
              elevation: 6,
              shape: const CircleBorder(),
              child: Container(
                alignment: Alignment.center,
                child: const Icon(Icons.drag_indicator, color: Colors.white),
              ),
            ),
          ),
          DevtoolUiState.expanded => NetworkToolWidget(),
          DevtoolUiState.maximized => const Placeholder(),
        };

        Size size = switch (_uiState) {
          DevtoolUiState.collapsed => const Size(56.0, 56.0),
          DevtoolUiState.expanded => Size(
            constraints.maxWidth,
            constraints.maxHeight / 3,
          ),
          DevtoolUiState.maximized => const Size(100.0, 100.0),
        };
        return FloatingButton(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          size: size,
          child: child,
        );
      },
    );
  }
}

mixin InAppNetworkToolStateMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    HttpOverrides.global = NetworkToolHttpOverrides();
  }

  @override
  void dispose() {
    HttpOverrides.global = null;
    super.dispose();
  }
}

enum DevtoolUiState { collapsed, expanded, maximized }

class NetworkToolWidget extends StatefulWidget {
  const NetworkToolWidget({super.key});

  @override
  State<NetworkToolWidget> createState() => NetworkToolWidgetState();
}

class NetworkToolWidgetState extends State<NetworkToolWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Column(
        children: [
          //Body
          Expanded(
            child: StreamBuilder(
              stream: NetworkToolHttpOverrides.httpProfiler
                  .getProfileDataStream(),
              builder: (context, snapshot) {
                return IgnorePointer(
                  child: ListView.builder(
                    itemCount: (snapshot.data?.length ?? 0).clamp(0, 1),
                    itemBuilder: (context, index) {
                      return Text(
                        snapshot.data?.reversed.toList()[index].toString() ??
                            '',
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
