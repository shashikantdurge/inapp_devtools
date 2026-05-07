import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:inapp_devtools/src/inapp_devtool/utils.dart';
import 'package:inapp_devtools/src/network_tool/http_profile_data.dart';
import 'package:inapp_devtools/src/network_tool/http_profiler.dart';

const _kRequestRowHeight = 36.0;
const _kSeparatorHeight = 1.0;

class NetworkTool extends StatefulWidget with InAppDevToolsItem {
  const NetworkTool({super.key, this.dataPreviewExtensions = const []});

  final List<DataPreviewExtension> dataPreviewExtensions;

  @override
  State<NetworkTool> createState() => _NetworkToolState();

  @override
  String get label => 'Network';
}

class _NetworkToolState extends State<NetworkTool> {
  final HeroController _heroController = HeroController();
  late ToolStateNotifier _toolStateNotifier;
  HttpProfileData? _selectedHttpProfileData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _toolStateNotifier = InAppDevTools.toolStateNotifier(context);
    final networkState = _toolStateNotifier.get<_NetworkToolState>() ?? this;
    _selectedHttpProfileData = networkState._selectedHttpProfileData;
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
      body: HeroControllerScope(
        controller: _heroController,
        child: Navigator(
          requestFocus: false,
          pages: [
            //Requests list page
            MaterialPage(
              child: _NetworkRequestListView(
                onItemTap: (data) {
                  setState(() {
                    _selectedHttpProfileData = data;
                  });
                },
              ),
            ),

            //Selected request details page
            if (_selectedHttpProfileData != null)
              _FadeTransitionPage(
                child: ListenableBuilder(
                  listenable: _selectedHttpProfileData!,
                  builder: (_, _) {
                    return _HttpProfileBodyWidget(
                      httpProfileData: _selectedHttpProfileData!,
                      dataPreviewExtensions: widget.dataPreviewExtensions,
                      popCallback: () {
                        setState(() {
                          _selectedHttpProfileData = null;
                        });
                      },
                    );
                  },
                ),
              ),
          ],
          onDidRemovePage: (page) {
            setState(() {
              _selectedHttpProfileData = null;
            });
          },
        ),
      ),
    );
  }
}

class _NetworkRequestListView extends StatefulWidget {
  const _NetworkRequestListView({required this.onItemTap});
  final void Function(HttpProfileData) onItemTap;

  @override
  State<_NetworkRequestListView> createState() =>
      __NetworkRequestListViewState();
}

class __NetworkRequestListViewState extends State<_NetworkRequestListView> {
  ScrollController scrollController = ScrollController();
  StreamSubscription? _profileDataLengthStreamSubscription;
  bool _maintainScrollState = false;

  @override
  void initState() {
    super.initState();
    _profileDataLengthStreamSubscription = HttpProfiler.instance
        .getProfileDataStream()
        .map((event) => event.length)
        .distinct()
        .listen((_) => scrollToUserScrolledPosition());
  }

  void scrollToUserScrolledPosition() {
    if (_maintainScrollState) {
      scrollController.jumpTo(
        scrollController.offset + _kSeparatorHeight + _kRequestRowHeight,
      );
    }
  }

  @override
  void dispose() {
    _profileDataLengthStreamSubscription?.cancel();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentBefore > 0) {
          _maintainScrollState = true;
        } else {
          _maintainScrollState = false;
        }
        return false;
      },
      child: StreamBuilder(
        stream: HttpProfiler.instance.getProfileDataStream(),
        initialData: HttpProfiler.instance.getProfileData(),
        builder: (context, snapshot) {
          final length = snapshot.data?.length ?? 0;
          return Scrollbar(
            controller: scrollController,
            interactive: true,
            trackVisibility: true,
            child: Align(
              alignment: Alignment.topCenter,
              child: CustomScrollView(
                controller: scrollController,
                reverse: true,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    sliver: SliverList.separated(
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey[850],
                        height: _kSeparatorHeight,
                      ),
                      itemCount: length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data![length - index - 1];
                        return ListenableBuilder(
                          listenable: data,
                          builder: (context, child) {
                            return _HttpProfileHeaderWidget(
                              httpProfileData: data,
                              onTap: () => widget.onItemTap(data),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SliverFillRemaining(
                    fillOverscroll: true,
                    hasScrollBody: false,
                    child: Container(
                      alignment: Alignment.center,
                      constraints: BoxConstraints(minHeight: 60),
                      child: Text(
                        'Start of the network logs',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HttpProfileHeaderWidget extends StatelessWidget {
  const _HttpProfileHeaderWidget({required this.httpProfileData, this.onTap});
  final EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8);
  final HttpProfileData httpProfileData;
  final VoidCallback? onTap;
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
      default:
        return Colors.black;
    }
  }

  /// Postman-style status colors: 1xx blue, 2xx green, 3xx amber, 4xx orange, 5xx red.
  Color getColorByStatusCode(int? statusCode) {
    if (statusCode == null) {
      if (httpProfileData.request.requestInProgress) {
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

  @override
  Widget build(BuildContext context) {
    final statusColor = getColorByStatusCode(
      httpProfileData.response.statusCode,
    );
    String displayUrl = httpProfileData.uri.path;
    if (httpProfileData.uri.hasQuery) {
      displayUrl += '?${httpProfileData.uri.query}';
    }
    if (httpProfileData.uri.hasFragment) {
      displayUrl += '#${httpProfileData.uri.fragment}';
    }

    Widget child = SizedBox(
      height: _kRequestRowHeight,
      child: Padding(
        padding: padding,
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: Text(
                httpProfileData.method.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: getColorByMethod(httpProfileData.method),
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
                    httpProfileData.statusCodeWithValue,
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
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(tag: httpProfileData, child: child),
    );
  }
}

String readableSize(int size) {
  if (size < 1024) {
    return '$size B';
  }
  return '${(size / 1024).toStringAsFixed(2)} KB';
}

class _HttpProfileBodyWidget extends StatefulWidget {
  const _HttpProfileBodyWidget({
    required this.httpProfileData,
    this.popCallback,
    this.dataPreviewExtensions = const [],
  });

  final HttpProfileData httpProfileData;
  final VoidCallback? popCallback;
  final List<DataPreviewExtension> dataPreviewExtensions;

  @override
  State<_HttpProfileBodyWidget> createState() => __HttpProfileBodyWidgetState();
}

class _Tab {
  final Widget tabView;
  final Tab tab;
  final String name;

  const _Tab({required this.tabView, required this.tab, required this.name});
}

class __HttpProfileBodyWidgetState extends State<_HttpProfileBodyWidget>
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
    final oldState = _toolStateNotifier.get<__HttpProfileBodyWidgetState>();
    if (oldState != null) {
      final index = tabViews.indexWhere((tab) => tab.name == oldState.tabName);
      if (index != -1) {
        _tabController.index = index;
      }
    }
  }

  @override
  void didUpdateWidget(covariant _HttpProfileBodyWidget oldWidget) {
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
    if (widget.httpProfileData.request.headers?['content-type']?.firstOrNull
        case String requestContentTypeString) {
      requestContentType = ContentType.parse(requestContentTypeString);
    }
    if (widget.httpProfileData.response.headers?['content-type']?.firstOrNull
        case String responseContentTypeString) {
      responseContentType = ContentType.parse(responseContentTypeString);
    }
    tabViews = [
      //Overview tab
      _Tab(
        tab: Tab(text: 'Overview', height: tabHeight),
        name: 'Overview',
        tabView: _TabViewOverview(
          httpProfileData: widget.httpProfileData,
          tabName: 'Overview',
        ),
      ),

      //Headers tab
      _Tab(
        tab: Tab(text: 'Headers', height: tabHeight),
        name: 'Headers',
        tabView: _TabViewHeaders(
          httpProfileData: widget.httpProfileData,
          tabName: 'Headers',
        ),
      ),

      //Request tab
      if (widget.httpProfileData.request.requestBody.isNotEmpty &&
          !widget.httpProfileData.request.requestInProgress)
        _Tab(
          tab: Tab(text: 'Request', height: tabHeight),
          name: 'Request',
          tabView: _DataPreviewTabView(
            tabName: 'Request',
            data: widget.httpProfileData.request.requestBody,
            contentType: requestContentType,
            dataPreviewExtensions: widget.dataPreviewExtensions,
          ),
        ),

      //Response tab
      if (widget.httpProfileData.response.responseBody.isNotEmpty &&
          widget.httpProfileData.response.responseInProgress == false)
        _Tab(
          tab: Tab(text: 'Response', height: tabHeight),
          name: 'Response',
          tabView: _DataPreviewTabView(
            tabName: 'Response',
            data: widget.httpProfileData.response.responseBody,
            contentType: responseContentType,
            dataPreviewExtensions: widget.dataPreviewExtensions,
          ),
        ),

      if (widget.httpProfileData.request.error case Object error)
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
                _HttpProfileHeaderWidget(
                  httpProfileData: widget.httpProfileData,
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
  const _TabViewOverview({
    required this.httpProfileData,
    required this.tabName,
  });
  final HttpProfileData httpProfileData;
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
    final data = widget.httpProfileData;
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
    debugPrint('Copy content: $content');
  }

  @override
  Widget build(BuildContext context) {
    Duration? responseTime;
    DateTime? startTime;
    DateTime? endTime;
    if (widget.httpProfileData.request.requestStartedAt
        case DateTime requestStartedAt) {
      startTime = requestStartedAt;
    }
    if (widget.httpProfileData.response.responseEndedAt
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
            valueWidget: Text(widget.httpProfileData.method.toUpperCase()),
          ),
          _KeyValueRowWidget(
            keyWidget: Text('Request URL'),
            valueWidget: Text(widget.httpProfileData.uri.toString()),
          ),
          _KeyValueRowWidget(
            keyWidget: Text('Status'),
            valueWidget: Text(widget.httpProfileData.statusCodeWithValue),
          ),
          if (widget.httpProfileData.response.headers case {
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
                  ClipboardData(text: widget.httpProfileData.toCurl()),
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
  const _TabViewHeaders({required this.httpProfileData, required this.tabName});
  final String tabName;
  final HttpProfileData httpProfileData;

  void copyHeadersContent() {
    final d = httpProfileData;
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
    debugPrint('Copy content: $content');
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
                valueWidget: Text(widget.httpProfileData.method.toUpperCase()),
              ),
              _KeyValueRowWidget(
                keyWidget: Text('Request URL'),
                valueWidget: Text(widget.httpProfileData.uri.toString()),
              ),
              _KeyValueRowWidget(
                keyWidget: Text('Status Code'),
                valueWidget: Text(widget.httpProfileData.statusCodeWithValue),
              ),
            ],
          ),

          if (widget.httpProfileData.response.headers
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

          if (widget.httpProfileData.request.headers
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
