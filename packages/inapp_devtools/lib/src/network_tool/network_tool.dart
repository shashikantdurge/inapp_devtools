import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:inapp_devtools/src/inapp_devtool/utils.dart';
import 'package:inapp_devtools/src/network_tool/network_profile_data.dart';
import 'package:inapp_devtools/src/network_tool/network_profiler.dart';
import 'package:inapp_devtools/src/network_tool/iad_clients/iad_http_client.dart';

const _kRequestRowHeight = 36.0;

class NetworkTool extends StatefulWidget with InAppDevToolsItem {
  const NetworkTool({
    super.key,
    this.dataPreviewExtensions = const [],
    this.networkRequestFilters = const [],
  });

  final List<DataPreviewExtension> dataPreviewExtensions;
  final List<NetworkProfileDataFilter> networkRequestFilters;

  @override
  String get label => 'Network';

  @override
  void initTool() {
    NetworkProfiler.ensureInitialized();
    HttpOverrides.global = IADNetworkHttpOverrides();
  }

  @override
  void disposeTool() {
    HttpOverrides.global = null;
    NetworkProfiler.instance = null;
  }

  @override
  State<NetworkTool> createState() => _NetworkToolState();
}

class _NetworkToolState extends State<NetworkTool> {
  final HeroController _heroController = HeroController();
  late ToolStateNotifier _toolStateNotifier;
  NetworkProfileData? _selectedProfileData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _toolStateNotifier = InAppDevTools.toolStateNotifier(context);
    final networkState = _toolStateNotifier.get<_NetworkToolState>() ?? this;
    _selectedProfileData = networkState._selectedProfileData;
  }

  @override
  void dispose() {
    _heroController.dispose();
    _toolStateNotifier.set(this, notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppDevToolsScaffold(
      appBar: InAppDevToolsAppBar(
        customActions: [
          IconButton(
            tooltip: 'Delete network logs',
            onPressed: () {
              NetworkProfiler.instance.clear();
              setState(() {
                _selectedProfileData = null;
              });
            },
            icon: Icon(Icons.delete_outline, color: Colors.white),
          ),
        ],
      ),
      body: HeroControllerScope(
        controller: _heroController,
        child: Navigator(
          requestFocus: false,
          pages: [
            //Requests list page
            MaterialPage(
              child: _NetworkRequestListView(
                requestFilters: widget.networkRequestFilters,
                onItemTap: (data) {
                  setState(() {
                    _selectedProfileData = data;
                  });
                },
              ),
            ),

            //Selected request details page
            if (_selectedProfileData != null)
              _FadeTransitionPage(
                child: ListenableBuilder(
                  listenable: _selectedProfileData!,
                  builder: (_, _) {
                    return _NetworkProfileBodyWidget(
                      profileData: _selectedProfileData!,
                      dataPreviewExtensions: widget.dataPreviewExtensions,
                      popCallback: () {
                        setState(() {
                          _selectedProfileData = null;
                        });
                      },
                    );
                  },
                ),
              ),
          ],
          onDidRemovePage: (page) {
            setState(() {
              _selectedProfileData = null;
            });
          },
        ),
      ),
    );
  }
}

class _NetworkRequestListView extends StatefulWidget {
  const _NetworkRequestListView({
    required this.onItemTap,
    required this.requestFilters,
  });
  final void Function(NetworkProfileData) onItemTap;
  final List<NetworkProfileDataFilter> requestFilters;
  @override
  State<_NetworkRequestListView> createState() =>
      __NetworkRequestListViewState();
}

class __NetworkRequestListViewState extends State<_NetworkRequestListView> {
  late ScrollController scrollController = ScrollController(
    initialScrollOffset:
        _filteredProfileDataNotifier.value.length * _kRequestRowHeight,
  );
  StreamSubscription? _profileDataStreamSubscription;
  bool _autoScrollToEnd = true;
  bool get autoScrollToEnd => _autoScrollToEnd;

  final ValueNotifier<List<NetworkProfileData>> _filteredProfileDataNotifier =
      ValueNotifier([]);
  final unreadProfileDataCountNotifier = ValueNotifier<int>(0);
  int lastLength = 0;
  set autoScrollToEnd(bool value) {
    if (value == _autoScrollToEnd) return;
    _autoScrollToEnd = value;
    if (value) {
      unreadProfileDataCountNotifier.value = 0;
    }
  }

  double get lastScrollOffset {
    final totalContentExtent =
        _filteredProfileDataNotifier.value.length * _kRequestRowHeight;
    if (!scrollController.hasClients ||
        totalContentExtent <= scrollController.position.extentInside) {
      return 0.0;
    }
    return totalContentExtent - scrollController.position.extentInside;
  }

  @override
  void initState() {
    super.initState();
    _profileDataStreamSubscription = NetworkProfiler.instance
        .getProfileDataStream()
        .listen(_onProfileDataReceived);
    _onProfileDataReceived(
      NetworkProfiler.instance.getProfileData() ?? [],
      notify: false,
    );
  }

  @override
  void didUpdateWidget(covariant _NetworkRequestListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestFilters != widget.requestFilters) {
      _onProfileDataReceived(
        NetworkProfiler.instance.getProfileData() ?? [],
        notify: false,
      );
    }
  }

  /// Filters the profile data and updates the [_filteredProfileDataNotifier]
  ///
  /// Automatically scrolls to the last item if [autoScrollToEnd] is true.
  void _onProfileDataReceived(
    List<NetworkProfileData> data, {
    bool notify = true,
  }) {
    _filteredProfileDataNotifier.value = data.where((request) {
      return widget.requestFilters.every((filter) => filter.matches(request));
    }).toList();

    if (_filteredProfileDataNotifier.value.length case int newLength
        when newLength != lastLength) {
      if (autoScrollToEnd || newLength == 0) {
        _ensureLastItemVisible();
      } else {
        unreadProfileDataCountNotifier.value += newLength - lastLength;
      }
      lastLength = newLength;
    }
  }

  void _ensureLastItemVisible() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        lastScrollOffset,
        duration: Duration(milliseconds: 160),
        curve: Curves.easeInOut,
      );
    }
    autoScrollToEnd = true;
  }

  void _onLayoutSizeChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (autoScrollToEnd) {
        _ensureLastItemVisible();
      }
    });
  }

  void _onUserScroll(UserScrollNotification notification) {
    if (notification.depth >= 1) return;
    if (notification.metrics.extentAfter > 0) {
      autoScrollToEnd = false;
    } else {
      autoScrollToEnd = true;
    }
  }

  @override
  void dispose() {
    _profileDataStreamSubscription?.cancel();
    _filteredProfileDataNotifier.dispose();
    unreadProfileDataCountNotifier.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const decoration = BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF303030), width: 1)),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Scrollbar(
          controller: scrollController,
          interactive: true,
          trackVisibility: true,
          child: Align(
            alignment: Alignment.topCenter,
            child: NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                _onLayoutSizeChanged();
                return true;
              },
              child: SizeChangedLayoutNotifier(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    _onUserScroll(notification);
                    return false;
                  },
                  child: ValueListenableBuilder(
                    valueListenable: _filteredProfileDataNotifier,
                    builder: (context, filteredProfileData, child) {
                      if (filteredProfileData.isEmpty) {
                        return const Center(
                          child: Text(
                            'Empty',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      final length = filteredProfileData.length;
                      return ListView.builder(
                        controller: scrollController,
                        itemExtent: _kRequestRowHeight,
                        itemCount: length,
                        itemBuilder: (context, index) {
                          final data = filteredProfileData[index];

                          return ListenableBuilder(
                            listenable: data,
                            builder: (context, child) {
                              return _NetworkProfileHeaderWidget(
                                profileData: data,
                                onTap: () => widget.onItemTap(data),
                                decoration: decoration,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: ValueListenableBuilder(
            valueListenable: unreadProfileDataCountNotifier,
            builder: (context, newProfileDataCount, _) {
              if (newProfileDataCount == 0) {
                return const SizedBox.shrink();
              }
              return FilledButton(
                onPressed: _ensureLastItemVisible,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.secondary,
                  ),
                  padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                child: Row(
                  spacing: 4,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_downward_rounded),
                    Text(newProfileDataCount.toString()),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NetworkProfileHeaderWidget extends StatelessWidget {
  const _NetworkProfileHeaderWidget({
    required this.profileData,
    this.onTap,
    this.decoration = const BoxDecoration(),
  });
  final EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8);
  final NetworkProfileData profileData;
  final VoidCallback? onTap;
  final Decoration decoration;
  Color getColorByMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return const Color(0xFF2AA198); // Postman Teal
      case 'POST':
        return const Color(0xFFFF6C37); // Postman Orange
      case 'PUT':
        return const Color(0xFF007AFF); // Postman Blue
      case 'DELETE':
        return const Color(0xFFD7263D); // Postman Red
      case 'PATCH':
        return const Color(0xFF6C71C4); // Postman Purple
      case 'HEAD':
        return const Color(0xFFB58900); // Postman Yellow
      case 'OPTIONS':
        return const Color(0xFF6C71C4); // Postman Purple
      case 'CONNECT':
        return const Color(0xFFB58900); // Postman Yellow
      case 'TRACE':
        return const Color(0xFF6C71C4); // Postman Purple
      default:
        return Colors.white;
    }
  }

  /// Postman-style status colors: 1xx blue, 2xx green, 3xx amber, 4xx orange, 5xx red.
  Color getColorByStatusCode(int? statusCode) {
    if (statusCode == null) {
      if (profileData.request.requestInProgress) {
        return const Color(0xFF9E9E9E);
      } else {
        return const Color(0xFFFF6C37);
      }
    }
    if (statusCode >= 100 && statusCode < 200) {
      return const Color(0xFF42A5F5);
    }
    if (statusCode >= 200 && statusCode < 300) {
      return const Color(0xFF4CAF50);
    }
    if (statusCode >= 300 && statusCode < 400) {
      return const Color(0xFFFFB74D);
    }
    if (statusCode >= 400 && statusCode < 500) {
      return const Color(0xFFFF6C37);
    }
    if (statusCode >= 500 && statusCode < 600) {
      return const Color(0xFFD7263D);
    }
    return const Color(0xFF9E9E9E);
  }

  String getDisplayText() {
    final uri = profileData.uri;
    final segs = uri.pathSegments;

    if (!segs.any((s) => s.isNotEmpty)) {
      return uri.toString();
    }

    StringBuffer result = StringBuffer();
    if (segs.isNotEmpty && segs.last.isNotEmpty) {
      result.write(segs.last);
    } else if (segs.length >= 2) {
      result.write(segs.sublist(segs.length - 2).join('/'));
    } else {
      return uri.toString();
    }

    if (uri.hasQuery) {
      result.write('?${uri.query}');
    }
    if (uri.hasFragment) {
      result.write('#${uri.fragment}');
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getColorByStatusCode(profileData.response.statusCode);
    final displayUrl = getDisplayText();

    Widget child = DecoratedBox(
      decoration: decoration,
      child: SizedBox(
        height: _kRequestRowHeight,
        child: Padding(
          padding: padding,
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  profileData.method.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: getColorByMethod(profileData.method),
                  ),
                ),
              ),
              Expanded(
                flex: 7,
                child: Text(
                  displayUrl,
                  style: TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      profileData.statusCodeWithValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: profileData,
        child: Tooltip(
          message: profileData.uri.toString(),
          showDuration: Duration(seconds: 3),
          child: child,
        ),
      ),
    );
  }
}

String readableSize(int size) {
  var bytes = 1024;
  if (size < 1024) {
    return '$size B';
  }
  bytes *= 1024;
  if (size < bytes) {
    return '${(size / 1024).toStringAsFixed(2)} KB';
  }
  bytes *= 1024;
  if (size < bytes) {
    return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
  }
  bytes *= 1024;
  return '${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

class _NetworkProfileBodyWidget extends StatefulWidget {
  const _NetworkProfileBodyWidget({
    required this.profileData,
    this.popCallback,
    this.dataPreviewExtensions = const [],
  });

  final NetworkProfileData profileData;
  final VoidCallback? popCallback;
  final List<DataPreviewExtension> dataPreviewExtensions;

  @override
  State<_NetworkProfileBodyWidget> createState() =>
      _NetworkProfileBodyWidgetState();
}

class _Tab {
  final Widget tabView;
  final Tab tab;
  final String name;

  const _Tab({required this.tabView, required this.tab, required this.name});
}

class _NetworkProfileBodyWidgetState extends State<_NetworkProfileBodyWidget>
    with TickerProviderStateMixin {
  late ToolStateNotifier _toolStateNotifier;
  late TabController _tabController;
  late List<_Tab> tabViews;
  late _NetworkActionsNotifier _networkActionsNotifier;
  static const tabHeight = 32.0;
  late final ValueNotifier<String> _activeNetworkTabNotifier;

  String get tabName => tabViews[_tabController.index].name;

  @override
  void initState() {
    super.initState();
    _initializeTabViews();
    _tabController = TabController(
      length: tabViews.length,
      vsync: this,
      initialIndex: 0,
    );
    _activeNetworkTabNotifier = ValueNotifier<String>(tabName);
    _updateActiveNetworkTab();
    _tabController.addListener(_onTabStateChange);
    _networkActionsNotifier = _NetworkActionsNotifier();
  }

  void _onTabStateChange() {
    final currentIndex = _tabController.index;
    _activeNetworkTabNotifier.value = tabViews[currentIndex].name;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _toolStateNotifier = InAppDevTools.toolStateNotifier(context);
    final oldState = _toolStateNotifier.get<_NetworkProfileBodyWidgetState>();
    if (oldState != null) {
      final index = tabViews.indexWhere((tab) => tab.name == oldState.tabName);
      if (index != -1) {
        _tabController.index = index;
      }
    }
  }

  @override
  void didUpdateWidget(covariant _NetworkProfileBodyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initializeTabViews();
    if (_tabController.length != tabViews.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: tabViews.length,
        vsync: this,
        animationDuration: _tabController.animationDuration,
        initialIndex: _tabController.index.clamp(0, tabViews.length - 1),
      );
      _tabController.addListener(_onTabStateChange);
      _updateActiveNetworkTab();
    }
  }

  void _updateActiveNetworkTab() => _activeNetworkTabNotifier.value = tabName;

  void _initializeTabViews() {
    ContentType? requestContentType, responseContentType;
    if (widget.profileData.request.headers?['content-type']?.firstOrNull
        case String requestContentTypeString) {
      requestContentType = ContentType.parse(requestContentTypeString);
    }
    if (widget.profileData.response.headers?['content-type']?.firstOrNull
        case String responseContentTypeString) {
      responseContentType = ContentType.parse(responseContentTypeString);
    }
    tabViews = [
      //Overview tab
      _Tab(
        tab: Tab(text: 'Overview', height: tabHeight),
        name: 'Overview',
        tabView: _TabViewOverview(
          profileData: widget.profileData,
          tabName: 'Overview',
        ),
      ),

      //Headers tab
      _Tab(
        tab: Tab(text: 'Headers', height: tabHeight),
        name: 'Headers',
        tabView: _TabViewHeaders(
          profileData: widget.profileData,
          tabName: 'Headers',
        ),
      ),

      //Request tab
      if (widget.profileData.request.requestBody.isNotEmpty &&
          !widget.profileData.request.requestInProgress)
        _Tab(
          tab: Tab(text: 'Request', height: tabHeight),
          name: 'Request',
          tabView: _DataPreviewTabView(
            tabName: 'Request',
            data: widget.profileData.request.requestBody,
            contentType: requestContentType,
            dataPreviewExtensions: widget.dataPreviewExtensions,
          ),
        ),

      //Response tab
      if (widget.profileData.response.responseBody.isNotEmpty &&
          widget.profileData.response.responseInProgress == false)
        _Tab(
          tab: Tab(text: 'Response', height: tabHeight),
          name: 'Response',
          tabView: _DataPreviewTabView(
            tabName: 'Response',
            data: widget.profileData.response.responseBody,
            contentType: responseContentType,
            dataPreviewExtensions: widget.dataPreviewExtensions,
          ),
        ),

      if (widget.profileData.request.error case Object error)
        _Tab(
          tab: Tab(text: 'Error', height: tabHeight),
          name: 'Error',
          tabView: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text('$error'),
          ),
        ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activeNetworkTabNotifier.dispose();
    _networkActionsNotifier.dispose();
    _toolStateNotifier.set(this, notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = InAppDevToolsTheme.of(context);

    return _NetworkDetailWidgetScope(
      activeNetworkTabNotifier: _activeNetworkTabNotifier,
      networkActionsNotifier: _networkActionsNotifier,
      child: Column(
        children: [
          ColoredBox(
            color: t.appBarBackgroundColor.withValues(alpha: 0.5),
            child: Column(
              children: [
                _NetworkProfileHeaderWidget(
                  profileData: widget.profileData,
                  onTap: widget.popCallback,
                ),
                Row(
                  children: [
                    //Tab Bar
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        indicatorSize: TabBarIndicatorSize.label,
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(
                            color: t.appBarMenuUnderlineColor,
                            width: 2,
                          ),
                          insets: EdgeInsets.zero,
                        ),
                        dividerColor: Colors.transparent,
                        dividerHeight: 1,
                        labelColor: const Color(0xFFE0E0E0),
                        unselectedLabelColor: const Color(0xFF9E9E9E),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed) ||
                              states.contains(WidgetState.hovered)) {
                            return t.appBarToolSelectorBackgroundColor
                                .withValues(alpha: 0.4);
                          }
                          return null;
                        }),
                        tabs: tabViews.map((tab) => tab.tab).toList(),
                      ),
                    ),

                    //Copy button
                    ValueListenableBuilder<String>(
                      valueListenable: _activeNetworkTabNotifier,
                      builder: (context, activeTabName, _) {
                        return ListenableBuilder(
                          listenable: _networkActionsNotifier,
                          builder: (BuildContext context, Widget? child) {
                            final copyContentCallback = _networkActionsNotifier
                                .copyContentCallback(activeTabName);
                            return IconButton(
                              onPressed: copyContentCallback,
                              icon: Icon(Icons.copy),
                            );
                          },
                        );
                      },
                    ),

                    //Close button
                    IconButton(
                      onPressed: widget.popCallback,
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabViews.map((tab) => tab.tabView).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

//################################## Overview tab widget ###################################

class _TabViewOverview extends StatefulWidget {
  const _TabViewOverview({required this.profileData, required this.tabName});
  final NetworkProfileData profileData;
  final String tabName;

  @override
  State<_TabViewOverview> createState() => _TabViewOverviewState();
}

class _TabViewOverviewState extends State<_TabViewOverview>
    with _TabStateChangeListener {
  @override
  String get tabName => widget.tabName;

  @override
  void onTabActive() {
    _NetworkDetailWidgetScope.of(context).networkActionsNotifier
        .setCopyContentCallback(copyOverviewContent, tabName);
  }

  void copyOverviewContent() {
    final data = widget.profileData;
    final firstLine = '${data.method.toUpperCase()} ${data.uri}';

    final lines = <String>[firstLine, 'Status: ${data.statusCodeWithValue}'];

    if (data.response.headers case {'content-type': [var contentType]}) {
      lines.add('Content Type: $contentType');
    }

    DateTime? startTime;
    DateTime? endTime;
    if (data.request.requestStartedAt case final DateTime requestStartedAt) {
      startTime = requestStartedAt;
    }
    if (data.response.responseEndedAt case final DateTime responseEndedAt) {
      endTime = responseEndedAt;
    }
    if (startTime != null && endTime != null) {
      final responseTime = endTime.difference(startTime);
      lines.add('Response Time: ${responseTime.inMilliseconds} ms');
    }
    if (startTime != null) {
      lines.add('Start Time: ${formatLocalTime(startTime)}');
    }
    if (endTime != null) {
      lines.add('End Time: ${formatLocalTime(endTime)}');
    }

    final content = lines.join('\n');
    Clipboard.setData(ClipboardData(text: content));
  }

  @override
  Widget build(BuildContext context) {
    Duration? responseTime;
    DateTime? startTime;
    DateTime? endTime;
    if (widget.profileData.request.requestStartedAt
        case DateTime requestStartedAt) {
      startTime = requestStartedAt;
    }
    if (widget.profileData.response.responseEndedAt
        case DateTime responseEndedAt) {
      endTime = responseEndedAt;
    }
    if (startTime != null && endTime != null) {
      responseTime = endTime.difference(startTime);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _KeyValueRowWidget(
            keyWidget: Text('Method'),
            valueWidget: Text(widget.profileData.method.toUpperCase()),
          ),
          _KeyValueRowWidget(
            keyWidget: Text('Request URL'),
            valueWidget: Text(widget.profileData.uri.toString()),
          ),
          _KeyValueRowWidget(
            keyWidget: Text('Status'),
            valueWidget: Text(widget.profileData.statusCodeWithValue),
          ),
          if (widget.profileData.response.headers case {
            'content-type': [var contentType],
          })
            _KeyValueRowWidget(
              keyWidget: Text('Content Type'),
              valueWidget: Text(contentType),
            ),

          Divider(),
          if (responseTime != null)
            _KeyValueRowWidget(
              keyWidget: Text('Response Time'),
              valueWidget: Text('${responseTime.inMilliseconds} ms'),
            ),
          if (startTime != null)
            _KeyValueRowWidget(
              keyWidget: Text('Start Time'),
              valueWidget: Text(formatLocalTime(startTime)),
            ),
          if (endTime != null)
            _KeyValueRowWidget(
              keyWidget: Text('End Time'),
              valueWidget: Text(formatLocalTime(endTime)),
            ),
          Divider(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: widget.profileData.toCurl()),
                );
              },
              icon: Icon(Icons.copy),
              label: Text('cURL Command'),
            ),
          ),
        ],
      ),
    );
  }
}

//################################## Headers tab widget ###################################

class _TabViewHeaders extends StatefulWidget {
  const _TabViewHeaders({required this.profileData, required this.tabName});
  final String tabName;
  final NetworkProfileData profileData;

  void copyHeadersContent() {
    final d = profileData;
    final buffer = StringBuffer()
      ..writeln('${d.method.toUpperCase()} ${d.uri}')
      ..writeln('Status Code: ${d.statusCodeWithValue}');

    if (d.response.headers case Map<String, List<String>> responseHeaders) {
      buffer.writeln();
      buffer.writeln('Response Headers');
      for (final e in responseHeaders.entries) {
        buffer.writeln('${e.key}: ${e.value.join(', ')}');
      }
    }

    if (d.request.headers case Map<String, List<String>> requestHeaders) {
      buffer.writeln();
      buffer.writeln('Request Headers');
      for (final e in requestHeaders.entries) {
        buffer.writeln('${e.key}: ${e.value.join(', ')}');
      }
    }

    final content = buffer.toString().trimRight();
    Clipboard.setData(ClipboardData(text: content));
  }

  @override
  State<_TabViewHeaders> createState() => _TabViewHeadersState();
}

class _TabViewHeadersState extends State<_TabViewHeaders>
    with _TabStateChangeListener {
  @override
  String get tabName => widget.tabName;

  @override
  void onTabActive() {
    _NetworkDetailWidgetScope.of(context).networkActionsNotifier
        .setCopyContentCallback(widget.copyHeadersContent, tabName);
  }

  late ToolStateNotifier toolStateNotifier;
  bool generalTabExpanded = true;
  bool responseHeadersTabExpanded = true;
  bool requestHeadersTabExpanded = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    toolStateNotifier = InAppDevTools.toolStateNotifier(context);
    final oldState = toolStateNotifier.get<_TabViewHeadersState>();
    if (oldState != null) {
      generalTabExpanded = oldState.generalTabExpanded;
      responseHeadersTabExpanded = oldState.responseHeadersTabExpanded;
      requestHeadersTabExpanded = oldState.requestHeadersTabExpanded;
    }
  }

  @override
  void dispose() {
    toolStateNotifier.set(this, notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpansionTile(
            title: Text('General'),
            initiallyExpanded: generalTabExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                generalTabExpanded = expanded;
              });
            },
            children: [
              _KeyValueRowWidget(
                keyWidget: Text('Method'),
                valueWidget: Text(widget.profileData.method.toUpperCase()),
              ),
              _KeyValueRowWidget(
                keyWidget: Text('Request URL'),
                valueWidget: Text(widget.profileData.uri.toString()),
              ),
              _KeyValueRowWidget(
                keyWidget: Text('Status Code'),
                valueWidget: Text(widget.profileData.statusCodeWithValue),
              ),
            ],
          ),

          if (widget.profileData.response.headers
              case Map<String, List<String>> headers)
            ExpansionTile(
              title: Text('Response Headers'),
              initiallyExpanded: responseHeadersTabExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  responseHeadersTabExpanded = expanded;
                });
              },
              children: [
                for (final header in headers.entries)
                  _KeyValueRowWidget(
                    keyWidget: Text(header.key),
                    valueWidget: Text(header.value.join(', ')),
                  ),
              ],
            ),

          if (widget.profileData.request.headers
              case Map<String, List<String>> headers)
            ExpansionTile(
              title: Text('Request Headers'),
              initiallyExpanded: requestHeadersTabExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  requestHeadersTabExpanded = expanded;
                });
              },
              children: [
                for (final header in headers.entries)
                  _KeyValueRowWidget(
                    keyWidget: Text(header.key),
                    valueWidget: Text(header.value.join(', ')),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

//################################## Payload tab widget ###################################

class _DataPreviewTabView extends StatefulWidget {
  const _DataPreviewTabView({
    required this.tabName,
    required this.data,
    required this.contentType,
    required this.dataPreviewExtensions,
  });
  final String tabName;
  final List<int> data;
  final ContentType? contentType;

  final List<DataPreviewExtension> dataPreviewExtensions;

  @override
  State<_DataPreviewTabView> createState() => __DataPreviewTabViewState();
}

class __DataPreviewTabViewState extends State<_DataPreviewTabView>
    with AutomaticKeepAliveClientMixin, _TabStateChangeListener {
  DataPreviewExtension? _supportedDataPreviewExtension;
  dynamic _previewExtensionData;

  @override
  void initState() {
    super.initState();
    final dataContext = DataContext(
      data: widget.data,
      contentType: widget.contentType,
    );
    for (final dataPreviewExtension in [
      ...widget.dataPreviewExtensions,
      DefaultDataPreviewExtension(),
    ]) {
      final data = dataPreviewExtension.mayInitialize(dataContext);
      if (data != null) {
        _supportedDataPreviewExtension = dataPreviewExtension;
        _previewExtensionData = data;
        break;
      }
    }
  }

  @override
  String get tabName => widget.tabName;

  @override
  bool get wantKeepAlive => true;

  @override
  void onTabActive() {
    _NetworkDetailWidgetScope.of(
      context,
    ).networkActionsNotifier.setCopyContentCallback(
      _supportedDataPreviewExtension?.copyContentCallback.call(
        _previewExtensionData,
      ),
      tabName,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_previewExtensionData != null &&
        _supportedDataPreviewExtension != null) {
      return _supportedDataPreviewExtension!.buildPreview(
        _previewExtensionData,
      );
    }
    return DefaultTextStyle(
      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Text.rich(
            TextSpan(children: [TextSpan(text: 'Data Preview not available')]),
          ),
          Text('Content Type: ${widget.contentType?.mimeType ?? 'unknown'}'),
          Text('Data Size: ${readableSize(widget.data.length)}'),
        ],
      ),
    );
  }
}

//################################## Common widgets ###################################

class _NetworkDetailWidgetScope extends InheritedWidget {
  final ValueNotifier<String> activeNetworkTabNotifier;
  final _NetworkActionsNotifier networkActionsNotifier;
  const _NetworkDetailWidgetScope({
    required this.activeNetworkTabNotifier,
    required this.networkActionsNotifier,
    required super.child,
  });

  @override
  bool updateShouldNotify(_NetworkDetailWidgetScope oldWidget) {
    return oldWidget.activeNetworkTabNotifier != activeNetworkTabNotifier ||
        oldWidget.networkActionsNotifier != networkActionsNotifier;
  }

  static _NetworkDetailWidgetScope of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_NetworkDetailWidgetScope>()!;
  }
}

/// Notifier for network actions like copy content.
class _NetworkActionsNotifier extends ChangeNotifier {
  final Map<String, VoidCallback?> _copyContentCallbacks = {};

  VoidCallback? copyContentCallback(String tabName) =>
      _copyContentCallbacks[tabName];

  void setCopyContentCallback(VoidCallback? callback, String tabName) {
    _copyContentCallbacks[tabName] = callback;
    Future.microtask(notifyListeners);
  }
}

//################################## Key Value Row Widget ###################################

class _KeyValueRowWidget extends StatelessWidget {
  const _KeyValueRowWidget({
    required this.keyWidget,
    required this.valueWidget,
  });
  final Widget keyWidget;
  final Widget valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(fontSize: 12, color: Colors.grey),
              child: keyWidget,
            ),
          ),
          Expanded(
            flex: 2,
            child: DefaultTextStyle(
              style: TextStyle(fontSize: 12),
              child: valueWidget,
            ),
          ),
        ],
      ),
    );
  }
}

//################################## Fade Transition Page ###################################

class _FadeTransitionPage extends Page<void> {
  const _FadeTransitionPage({required this.child});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      barrierColor: Theme.of(context).colorScheme.surface,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInExpo,
        );
        return FadeTransition(opacity: curvedAnimation, child: child);
      },
    );
  }
}

mixin _TabStateChangeListener<T extends StatefulWidget> on State<T> {
  String get tabName;
  ValueNotifier<String>? _activeNetworkTabNotifier;
  bool? _lastIsActive;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lastIsActive == null) {
      _activeNetworkTabNotifier ??= _NetworkDetailWidgetScope.of(
        context,
      ).activeNetworkTabNotifier;
      _activeNetworkTabNotifier!.removeListener(_onActiveTabChanged);
      _activeNetworkTabNotifier!.addListener(_onActiveTabChanged);
      _onActiveTabChanged();
    }
  }

  void _onActiveTabChanged() {
    final isActive = _activeNetworkTabNotifier!.value == tabName;
    if (_lastIsActive != isActive) {
      _lastIsActive = isActive;
      if (isActive) {
        onTabActive();
      }
    }
  }

  void onTabActive();

  @override
  void dispose() {
    _activeNetworkTabNotifier?.removeListener(_onActiveTabChanged);
    super.dispose();
  }
}
