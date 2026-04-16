import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:inapp_devtools/src/inapp_devtool/utils.dart';
import 'package:inapp_devtools/src/network_tool/http_profile_data.dart';
import 'package:inapp_devtools/src/network_tool/http_profiler.dart';

class InAppDevtoolNetwork extends StatefulWidget with InAppDevToolsItem {
  const InAppDevtoolNetwork({super.key});

  @override
  State<InAppDevtoolNetwork> createState() => _InAppDevtoolNetworkState();

  @override
  String get label => 'Network';
}

class _InAppDevtoolNetworkState extends State<InAppDevtoolNetwork> {
  final HeroController _heroController = HeroController();
  HttpProfileData? _selectedHttpProfileData;

  @override
  void dispose() {
    _heroController.dispose();
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
                        Divider(color: Colors.grey[850]),
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      final data = snapshot.data![index];
                      return _HttpProfileHeaderWidget(
                        httpProfileData: data,
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
            httpProfileData.response.statusCode?.toString() ?? '',
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

class _HttpProfileBodyWidget extends StatefulWidget {
  const _HttpProfileBodyWidget({
    required this.httpProfileData,
    this.popCallback,
  });
  final HttpProfileData httpProfileData;
  final VoidCallback? popCallback;

  @override
  State<_HttpProfileBodyWidget> createState() => __HttpProfileBodyWidgetState();
}

class __HttpProfileBodyWidgetState extends State<_HttpProfileBodyWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = InAppDevToolsTheme.of(context);
    const tabHeight = 32.0;
    List<(Tab, Widget)> tabViews = [
      //Overview tab
      (
        Tab(text: 'Overview', height: tabHeight),
        _TabViewOverview(httpProfileData: widget.httpProfileData),
      ),

      //Headers tab
      (
        Tab(text: 'Headers', height: tabHeight),
        _TabViewHeaders(httpProfileData: widget.httpProfileData),
      ),

      //Request tab
      if (widget.httpProfileData.request.requestBody.isNotEmpty)
        (
          Tab(text: 'Request', height: tabHeight),
          _TabViewRequest(httpProfileData: widget.httpProfileData),
        ),

      //Response tab
      if (widget.httpProfileData.response.responseBody.isNotEmpty)
        (
          Tab(text: 'Response', height: tabHeight),
          _TabViewResponse(httpProfileData: widget.httpProfileData),
        ),
    ];

    return DefaultTabController(
      length: tabViews.length,
      child: Column(
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
                    Expanded(
                      child: TabBar(
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
                        tabs: tabViews.map((tab) => tab.$1).toList(),
                      ),
                    ),
                    IconButton(onPressed: null, icon: Icon(Icons.copy)),
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
            child: TabBarView(children: tabViews.map((tab) => tab.$2).toList()),
          ),
        ],
      ),
    );
  }
}

//################################## Overview tab widget ###################################

class _TabViewOverview extends StatelessWidget {
  const _TabViewOverview({required this.httpProfileData});
  final HttpProfileData httpProfileData;
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
            valueWidget: Text(
              [
                httpProfileData.response.statusCode?.toString() ?? '',
                httpProfileData.response.reasonPhrase ?? '',
              ].join(' '),
            ),
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

class _TabViewHeaders extends StatefulWidget {
  const _TabViewHeaders({required this.httpProfileData});
  final HttpProfileData httpProfileData;

  @override
  State<_TabViewHeaders> createState() => _TabViewHeadersState();
}

class _TabViewHeadersState extends State<_TabViewHeaders> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpansionTile(
            title: Text('General'),
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
                valueWidget: Text(
                  [
                    widget.httpProfileData.response.statusCode?.toString() ??
                        '',
                    widget.httpProfileData.response.reasonPhrase ?? '',
                  ].join(' '),
                ),
              ),
            ],
          ),

          if (widget.httpProfileData.response.headers
              case Map<String, List<String>> headers)
            ExpansionTile(
              title: Text('Response Headers'),
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

class _TabViewResponse extends StatelessWidget {
  const _TabViewResponse({required this.httpProfileData});
  final HttpProfileData httpProfileData;

  @override
  Widget build(BuildContext context) {
    return _DataDisplayWidget(
      data: httpProfileData.response.responseBody,
      contentType: httpProfileData.response.headers?['content-type']?.first,
    );
  }
}

//################################## Payload tab widget ###################################

class _TabViewRequest extends StatelessWidget {
  const _TabViewRequest({required this.httpProfileData});
  final HttpProfileData httpProfileData;
  @override
  Widget build(BuildContext context) {
    return _DataDisplayWidget(
      data: httpProfileData.request.requestBody,
      contentType: httpProfileData.request.headers?['content-type']?.first,
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
      try {
        final json = jsonDecode(utf8DecodedBody);
        return JsonTreeWidget(json: json, expandDepth: 1);
      } catch (e) {
        return buildScrollableText(utf8DecodedBody);
      }
    } on FormatException {
      if (widget.contentType?.contains('image/') ?? false) {
        return Image.memory(
          Uint8List.fromList(widget.data),
          errorBuilder: (context, error, stackTrace) {
            return buildScrollableText('Binary data:\n${widget.data}');
          },
        );
      }
      rethrow;
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
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 220),
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
