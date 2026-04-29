import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:inapp_devtools/src/inapp_devtool/utils.dart';
import 'package:inapp_devtools/src/network_tool/http_profile_data.dart';
import 'package:inapp_devtools/src/network_tool/http_profiler.dart';

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
          pages: [
            //Requests list page
            MaterialPage(
              child: StreamBuilder(
                stream: HttpProfiler.instance.getProfileDataStream(),
                builder: (context, snapshot) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    separatorBuilder: (context, index) =>
                        Divider(color: Colors.grey[850], height: 1),
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      final data = snapshot.data![index];
                      return _HttpProfileHeaderWidget(
                        httpProfileData: data,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedHttpProfileData = data;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),

            //Selected request details page
            if (_selectedHttpProfileData != null)
              _FadeTransitionPage(
                child: _HttpProfileBodyWidget(
                  httpProfileData: _selectedHttpProfileData!,
                  dataPreviewExtensions: widget.dataPreviewExtensions,
                  popCallback: () {
                    setState(() {
                      _selectedHttpProfileData = null;
                    });
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

class _HttpProfileHeaderWidget extends StatelessWidget {
  const _HttpProfileHeaderWidget({
    required this.httpProfileData,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.onTap,
  });
  final EdgeInsets padding;
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
  Color getColorByStatusCode(int statusCode) {
    if (statusCode == 0) {
      return const Color(0xFF9E9E9E);
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
      httpProfileData.response.statusCode ?? 0,
    );
    String displayUrl = httpProfileData.uri.path;
    if (httpProfileData.uri.hasQuery) {
      displayUrl += '?${httpProfileData.uri.query}';
    }
    if (httpProfileData.uri.hasFragment) {
      displayUrl += '#${httpProfileData.uri.fragment}';
    }

    Widget child = Row(
      spacing: 8,
      children: [
        Text(
          httpProfileData.method.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: getColorByMethod(httpProfileData.method),
          ),
        ),
        Expanded(child: Text(displayUrl, style: TextStyle(fontSize: 12))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            httpProfileData.response.statusCode?.toString() ?? 'pending',
            style: TextStyle(fontSize: 12, color: statusColor),
          ),
        ),
      ],
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: padding,
        child: Hero(tag: httpProfileData, child: child),
      ),
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
  static const tabHeight = 32.0;

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
        initialIndex: _tabController.index,
      );
    }
  }

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
        tabView: _TabViewOverview(httpProfileData: widget.httpProfileData),
      ),

      //Headers tab
      _Tab(
        tab: Tab(text: 'Headers', height: tabHeight),
        name: 'Headers',
        tabView: _TabViewHeaders(httpProfileData: widget.httpProfileData),
      ),

      //Request tab
      if (widget.httpProfileData.request.requestBody.isNotEmpty)
        _Tab(
          tab: Tab(text: 'Request', height: tabHeight),
          name: 'Request',
          tabView: _DataPreviewTabView(
            data: widget.httpProfileData.request.requestBody,
            contentType: requestContentType,
            dataPreviewExtensions: widget.dataPreviewExtensions,
          ),
        ),

      //Response tab
      if (widget.httpProfileData.response.responseBody.isNotEmpty)
        _Tab(
          tab: Tab(text: 'Response', height: tabHeight),
          name: 'Response',
          tabView: _DataPreviewTabView(
            data: widget.httpProfileData.response.responseBody,
            contentType: responseContentType,
            dataPreviewExtensions: widget.dataPreviewExtensions,
          ),
        ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _toolStateNotifier.set(this, notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = InAppDevToolsTheme.of(context);

    return Column(
      children: [
        ColoredBox(
          color: t.appBarBackgroundColor.withValues(alpha: 0.5),
          child: Column(
            children: [
              _HttpProfileHeaderWidget(
                httpProfileData: widget.httpProfileData,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                          return t.appBarToolSelectorBackgroundColor.withValues(
                            alpha: 0.4,
                          );
                        }
                        return null;
                      }),
                      tabs: tabViews.map((tab) => tab.tab).toList(),
                    ),
                  ),

                  //Copy button
                  Builder(
                    builder: (context) {
                      return ListenableBuilder(
                        listenable: _tabController,
                        builder: (BuildContext context, Widget? child) {
                          final index = _tabController.index;
                          final widget = tabViews[index].tabView;
                          return IconButton(
                            onPressed: widget is _CopyableWidget
                                ? () {
                                    if (widget.getWidgetContent()
                                        case String content) {
                                      Clipboard.setData(
                                        ClipboardData(text: content),
                                      );
                                    }
                                  }
                                : null,
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
    );
  }
}

//################################## Overview tab widget ###################################

class _TabViewOverview extends StatelessWidget with _CopyableWidget {
  const _TabViewOverview({required this.httpProfileData});
  final HttpProfileData httpProfileData;

  @override
  String? getWidgetContent() {
    final data = httpProfileData;
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

    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    Duration? responseTime;
    DateTime? startTime;
    DateTime? endTime;
    if (httpProfileData.request.requestStartedAt
        case DateTime requestStartedAt) {
      startTime = requestStartedAt;
    }
    if (httpProfileData.response.responseEndedAt
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
            valueWidget: Text(httpProfileData.method.toUpperCase()),
          ),
          _KeyValueRowWidget(
            keyWidget: Text('Request URL'),
            valueWidget: Text(httpProfileData.uri.toString()),
          ),
          _KeyValueRowWidget(
            keyWidget: Text('Status'),
            valueWidget: Text(httpProfileData.statusCodeWithValue),
          ),
          if (httpProfileData.response.headers case {
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
                  ClipboardData(text: httpProfileData.toCurl()),
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

class _TabViewHeaders extends StatefulWidget with _CopyableWidget {
  const _TabViewHeaders({required this.httpProfileData});
  final HttpProfileData httpProfileData;

  @override
  String? getWidgetContent() {
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

    return buffer.toString().trimRight();
  }

  @override
  State<_TabViewHeaders> createState() => _TabViewHeadersState();
}

class _TabViewHeadersState extends State<_TabViewHeaders> {
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

//################################## Response tab widget ###################################

class _TabViewResponse extends StatefulWidget with _CopyableWidget {
  const _TabViewResponse({required this.httpProfileData});
  final HttpProfileData httpProfileData;

  @override
  String? getWidgetContent() {
    try {
      final utf8DecodedBody = utf8.decode(
        httpProfileData.response.responseBody,
      );
      try {
        return JsonEncoder.withIndent(
          '\t',
        ).convert(jsonDecode(utf8DecodedBody));
      } catch (e) {
        return utf8DecodedBody;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  State<_TabViewResponse> createState() => _TabViewResponseState();
}

class _TabViewResponseState extends State<_TabViewResponse>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _DataDisplayWidget(
      data: widget.httpProfileData.response.responseBody,
      contentType:
          widget.httpProfileData.response.headers?['content-type']?.first,
    );
  }
}

//################################## Payload tab widget ###################################

class _DataPreviewTabView extends StatefulWidget {
  const _DataPreviewTabView({
    required this.data,
    required this.contentType,
    required this.dataPreviewExtensions,
  });

  final List<int> data;
  final ContentType? contentType;

  final List<DataPreviewExtension> dataPreviewExtensions;

  @override
  State<_DataPreviewTabView> createState() => __DataPreviewTabViewState();
}

class __DataPreviewTabViewState extends State<_DataPreviewTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final contentType = widget.contentType;
    if (contentType == null) {
      return const Placeholder();
    }
    for (final dataPreviewExtension in widget.dataPreviewExtensions) {
      if (dataPreviewExtension.isSupported(contentType)) {
        return dataPreviewExtension.buildPreview(
          DataContext(data: widget.data, contentType: contentType),
        );
      }
    }
    return const Placeholder();
  }
}

class _TabViewRequest extends StatefulWidget with _CopyableWidget {
  const _TabViewRequest({required this.httpProfileData});
  final HttpProfileData httpProfileData;

  @override
  String? getWidgetContent() {
    try {
      final utf8DecodedBody = utf8.decode(httpProfileData.request.requestBody);
      try {
        return JsonEncoder.withIndent(
          '\t',
        ).convert(jsonDecode(utf8DecodedBody));
      } catch (e) {
        return utf8DecodedBody;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  State<_TabViewRequest> createState() => _TabViewRequestState();
}

class _TabViewRequestState extends State<_TabViewRequest>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _DataDisplayWidget(
      data: widget.httpProfileData.request.requestBody,
      contentType:
          widget.httpProfileData.request.headers?['content-type']?.first,
    );
  }
}

//################################## Common widgets ###################################

class _DataDisplayWidget extends StatefulWidget {
  const _DataDisplayWidget({required this.data, required this.contentType});
  final List<int> data;
  final String? contentType;

  @override
  State<_DataDisplayWidget> createState() => _DataDisplayWidgetState();
}

class _DataDisplayWidgetState extends State<_DataDisplayWidget> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildScrollableText(String text) {
      return Scrollbar(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Text(text),
        ),
      );
    }

    try {
      final utf8DecodedBody = utf8.decode(widget.data);
      return buildScrollableText(utf8DecodedBody);
    } on FormatException {
      if (widget.contentType?.contains('image/') ?? false) {
        return Image.memory(
          Uint8List.fromList(widget.data),
          errorBuilder: (context, error, stackTrace) {
            return buildScrollableText('Binary data:\n${widget.data}');
          },
        );
      }
      return buildScrollableText('Binary data:\n${widget.data}');
    } catch (e) {
      return buildScrollableText('Binary data:\n${widget.data}');
    }
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

mixin _CopyableWidget on Widget {
  String? getWidgetContent();
}
