import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NestedScrollViewExamplePage(),
    );
  }
}

class SubordinateScrollController extends ScrollController {
  SubordinateScrollController({
    required ScrollController parent,
    String? debugLabel,
  }) : _parent = parent,
       super(
         initialScrollOffset: parent.initialScrollOffset,
         keepScrollOffset: parent.keepScrollOffset,
         debugLabel: switch ((parent.debugLabel, debugLabel)) {
           (null, null) => null,
           (null, String label) => label,
           (String label, null) => '$label/sub',
           (String parentLabel, String label) => '$parentLabel/$label',
         },
       );

  final ScrollController _parent;
  bool _isActive = false;

  ScrollController get parent => _parent;

  bool get isActive => _isActive;
  set isActive(bool value) {
    if (_isActive != value) {
      _isActive = value;
      if (_isActive) {
        _attachToParent();
      } else {
        _detachFromParent();
      }
    }
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _parent.createScrollPosition(physics, context, oldPosition);
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    if (_isActive) {
      _parent.attach(position);
    }
  }

  @override
  void detach(ScrollPosition position) {
    if (_isActive) {
      _parent.detach(position);
    }
    super.detach(position);
  }

  void _detachFromParent() {
    for (final position in positions) {
      _parent.detach(position);
    }
  }

  void _attachToParent() {
    for (final position in positions) {
      _parent.attach(position);
    }
  }

  @override
  void dispose() {
    if (isActive) {
      isActive = false;
    }
    super.dispose();
  }
}

class SubordinateScrollControllerProvider extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const SubordinateScrollControllerProvider({
    super.key,
    required this.isActive,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() =>
      _SubordinateScrollControllerProviderState();
}

class _SubordinateScrollControllerProviderState
    extends State<SubordinateScrollControllerProvider> {
  SubordinateScrollController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentController = PrimaryScrollController.of(context);

    if (parentController != _controller?.parent) {
      _controller?.dispose();
      _controller = SubordinateScrollController(parent: parentController);
      _controller!.isActive = widget.isActive;
    }
  }

  @override
  void didUpdateWidget(
    covariant SubordinateScrollControllerProvider oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    _controller!.isActive = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller!,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class Page extends StatefulWidget {
  final int number;
  final int size;

  const Page({super.key, required this.number, required this.size});

  @override
  State<Page> createState() => _PageState();
}

class _PageState extends State<Page> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final overlapAbsorberHandle =
        NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 1)),
      // avoid indicator overlap
      edgeOffset: overlapAbsorberHandle.layoutExtent ?? 0,
      child: Scrollbar(
        child: CustomScrollView(
          controller: PrimaryScrollController.of(context),
          slivers: [
            SliverOverlapInjector(handle: overlapAbsorberHandle),
            SliverList(
              delegate: SliverChildBuilderDelegate(childCount: widget.size, (
                context,
                index,
              ) {
                return ListTile(
                  title: Text('Page ${widget.number} -Item $index'),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class NestedScrollViewScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

class NestedScrollViewExamplePage extends StatefulWidget {
  const NestedScrollViewExamplePage({super.key});

  @override
  State<NestedScrollViewExamplePage> createState() =>
      _NestedScrollViewExamplePageState();
}

class _NestedScrollViewExamplePageState
    extends State<NestedScrollViewExamplePage> {
  int _tabIndex = 0;
  final _scrollBehavior = NestedScrollViewScrollBehavior();

  void _handleTabBarTap(int index, BuildContext context) {
    final scrollController = PrimaryScrollController.of(context);
    if (index == _tabIndex) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _tabIndex = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: _scrollBehavior,
      child: Scaffold(
        body: DefaultTabController(
          initialIndex: _tabIndex,
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: Builder(
                    builder: (context) {
                      final controller = DefaultTabController.of(context);
                      return SliverAppBar(
                        pinned: true,
                        floating: true,
                        snap: true,
                        forceElevated: innerBoxIsScrolled,
                        title: Text('NestedScrollView Example'),
                        bottom: TabBar(
                          onTap: (index) => _handleTabBarTap(index, context),
                          tabs: [
                            for (var i = 0; i < controller.length; ++i)
                              Tab(text: "Tab $i"),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ];
            },
            body: Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return TabBarView(
                  children: [
                    for (var i = 0; i < controller.length; ++i)
                      ListenableBuilder(
                        key: Key("Key$i"),
                        listenable: controller,
                        builder: (context, child) {
                          // rebuild the [SubordinateScrollControllerProvider] when the tab index changes
                          return SubordinateScrollControllerProvider(
                            // should scroll position attached by the subtree be active
                            isActive: controller.index == i,
                            child: Page(number: i, size: 20 * (i + 1)),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SubordinateScrollController2 extends ScrollController {
  SubordinateScrollController2({
    required ScrollController parent,
    String? debugLabel,
  }) : _parent = parent,
       super(
         initialScrollOffset: parent.initialScrollOffset,
         keepScrollOffset: parent.keepScrollOffset,
         debugLabel: switch ((parent.debugLabel, debugLabel)) {
           (null, null) => null,
           (null, String label) => label,
           (String label, null) => '$label/sub',
           (String parentLabel, String label) => '$parentLabel/$label',
         },
       );

  final ScrollController _parent;
  bool _isActive = false;

  ScrollController get parent => _parent;

  bool get isActive => _isActive;
  set isActive(bool value) {
    if (_isActive != value) {
      _isActive = value;
      if (_isActive) {
        _attachToParent();
      } else {
        _detachFromParent();
      }
    }
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _parent.createScrollPosition(physics, context, oldPosition);
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    if (_isActive) {
      _parent.attach(position);
    }
  }

  @override
  void detach(ScrollPosition position) {
    if (_isActive) {
      _parent.detach(position);
    }
    super.detach(position);
  }

  void _detachFromParent() {
    for (final position in positions) {
      _parent.detach(position);
    }
  }

  void _attachToParent() {
    for (final position in positions) {
      _parent.attach(position);
    }
  }

  @override
  void dispose() {
    if (isActive) {
      isActive = false;
    }
    super.dispose();
  }
}

class SubordinateScrollControllerProvider2 extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const SubordinateScrollControllerProvider2({
    super.key,
    required this.isActive,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() =>
      _SubordinateScrollControllerProviderState2();
}

class _SubordinateScrollControllerProviderState2
    extends State<SubordinateScrollControllerProvider2> {
  SubordinateScrollController2? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentController = PrimaryScrollController.of(context);

    if (parentController != _controller?.parent) {
      _controller?.dispose();
      _controller = SubordinateScrollController2(parent: parentController);
      _controller!.isActive = widget.isActive;
    }
  }

  @override
  void didUpdateWidget(
    covariant SubordinateScrollControllerProvider2 oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    _controller!.isActive = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller!,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class Page2 extends StatefulWidget {
  final int number;
  final int size;

  const Page2({super.key, required this.number, required this.size});

  @override
  State<Page2> createState() => _PageState2();
}

class _PageState2 extends State<Page2> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final overlapAbsorberHandle =
        NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 1)),
      // avoid indicator overlap
      edgeOffset: overlapAbsorberHandle.layoutExtent ?? 0,
      child: Scrollbar(
        child: CustomScrollView(
          controller: PrimaryScrollController.of(context),
          slivers: [
            SliverOverlapInjector(handle: overlapAbsorberHandle),
            SliverList(
              delegate: SliverChildBuilderDelegate(childCount: widget.size, (
                context,
                index,
              ) {
                return ListTile(
                  title: Text('Page ${widget.number} -Item $index'),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class NestedScrollViewScrollBehavior2 extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

class NestedScrollViewExamplePage2 extends StatefulWidget {
  const NestedScrollViewExamplePage2({super.key});

  @override
  State<NestedScrollViewExamplePage2> createState() =>
      _NestedScrollViewExamplePageState2();
}

class _NestedScrollViewExamplePageState2
    extends State<NestedScrollViewExamplePage2> {
  int _tabIndex = 0;
  final _scrollBehavior = NestedScrollViewScrollBehavior();

  void _handleTabBarTap(int index, BuildContext context) {
    final scrollController = PrimaryScrollController.of(context);
    if (index == _tabIndex) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _tabIndex = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: _scrollBehavior,
      child: Scaffold(
        body: DefaultTabController(
          initialIndex: _tabIndex,
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: Builder(
                    builder: (context) {
                      final controller = DefaultTabController.of(context);
                      return SliverAppBar(
                        pinned: true,
                        floating: true,
                        snap: true,
                        forceElevated: innerBoxIsScrolled,
                        title: Text('NestedScrollView Example'),
                        bottom: TabBar(
                          onTap: (index) => _handleTabBarTap(index, context),
                          tabs: [
                            for (var i = 0; i < controller.length; ++i)
                              Tab(text: "Tab $i"),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ];
            },
            body: Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return TabBarView(
                  children: [
                    for (var i = 0; i < controller.length; ++i)
                      ListenableBuilder(
                        key: Key("Key$i"),
                        listenable: controller,
                        builder: (context, child) {
                          // rebuild the [SubordinateScrollControllerProvider] when the tab index changes
                          return SubordinateScrollControllerProvider(
                            // should scroll position attached by the subtree be active
                            isActive: controller.index == i,
                            child: Page(number: i, size: 20 * (i + 1)),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
