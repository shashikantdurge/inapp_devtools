import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
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
  @override
  Widget build(BuildContext context) {
    return InAppDevToolsScaffold(
      body: StreamBuilder(
        stream: HttpProfiler.instance.getProfileDataStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return _HttpProfileBodyWidget(httpProfileData: snapshot.data![0]);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey[850]),
            itemCount: snapshot.data?.length ?? 0,
            itemBuilder: (context, index) {
              return _HttpProfileHeaderWidget(
                httpProfileData: snapshot.data![index],
              );
            },
          );
        },
      ),
    );
  }
}

class _HttpProfileHeaderWidget extends StatelessWidget {
  const _HttpProfileHeaderWidget({required this.httpProfileData});

  final HttpProfileData httpProfileData;

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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
          Expanded(
            child: Text(
              httpProfileData.uri.toString(),
              style: TextStyle(fontSize: 12),
            ),
          ),
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
      ),
    );
  }
}

class _HttpProfileBodyWidget extends StatefulWidget {
  const _HttpProfileBodyWidget({required this.httpProfileData});
  final HttpProfileData httpProfileData;

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
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Headers'),
            Tab(text: 'Payload'),
            Tab(text: 'Preview'),
            Tab(text: 'Response'),
          ],
        ),
        Expanded(
          child: _HttpProfileBodyHeadersTabWidget(
            httpProfileData: widget.httpProfileData,
          ),
        ),
      ],
    );
  }
}

class _HttpProfileBodyHeadersTabWidget extends StatefulWidget {
  const _HttpProfileBodyHeadersTabWidget({required this.httpProfileData});
  final HttpProfileData httpProfileData;

  @override
  State<_HttpProfileBodyHeadersTabWidget> createState() =>
      _HttpProfileBodyHeadersTabWidgetState();
}

class _HttpProfileBodyHeadersTabWidgetState
    extends State<_HttpProfileBodyHeadersTabWidget> {
  bool _requestHeadersExpanded = false;
  bool _responseHeadersExpanded = false;

  void _onRequestHeadersTitleTap() {
    setState(() {
      _requestHeadersExpanded = !_requestHeadersExpanded;
    });
  }

  void _onResponseHeadersTitleTap() {
    setState(() {
      _responseHeadersExpanded = !_responseHeadersExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeadersWidget(
            title: 'Response Headers',
            headers: widget.httpProfileData.response.headers ?? {},
            expanded: _responseHeadersExpanded,
            onTitleTap: _onResponseHeadersTitleTap,
          ),
          Divider(color: Colors.grey[850], height: 1),
          _HeadersWidget(
            title: 'Request Headers',
            headers: widget.httpProfileData.request.headers ?? {},
            expanded: _requestHeadersExpanded,
            onTitleTap: _onRequestHeadersTitleTap,
          ),
        ],
      ),
    );
  }
}

class _HeadersWidget extends StatelessWidget {
  const _HeadersWidget({
    required this.title,
    required this.headers,
    this.expanded = false,
    required this.onTitleTap,
  });
  final String title;
  final bool expanded;
  final Map<String, List<String>> headers;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTitleTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                Text(
                  expanded ? title : '$title (${headers.length})',
                  style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                ),
                Spacer(),
                if (expanded)
                  Icon(Icons.keyboard_arrow_up)
                else
                  Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final header in headers.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Row(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      header.key,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      header.value.join(', '),
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
