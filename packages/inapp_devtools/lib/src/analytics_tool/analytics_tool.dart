import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:intl/intl.dart';

import 'analytics_profile_data.dart';

const _kAnalyticsRowHeight = 36.0;
const _kDividerHeight = 6.0;
const numerator = 1;
const denominator = 3;
const part = 2 / (denominator + numerator);

class _AnalyticsItemInfo {
  final AnalyticsProfileData data;
  double height;
  bool expanded;
  _AnalyticsItemInfo({
    required this.data,
    this.expanded = false,
    this.height = _kAnalyticsRowHeight + _kDividerHeight * 2,
  });
}

/// Shows analytics entries captured by [AnalyticsProfiler].
///
/// This widget does not include internal page navigation and renders a single
/// expandable list where each tile can reveal event parameters.
class AnalyticsTool extends StatefulWidget with InAppDevToolsItem {
  const AnalyticsTool({super.key});

  @override
  String get label => 'Analytics';

  @override
  void initTool() {
    AnalyticsProfiler.ensureInitialized();
  }

  @override
  void disposeTool() {
    AnalyticsProfiler.instance = null;
  }

  @override
  State<AnalyticsTool> createState() => _AnalyticsToolState();
}

class _AnalyticsToolState extends State<AnalyticsTool> {
  late ScrollController _scrollController;
  StreamSubscription<List<AnalyticsProfileData>>? _profileDataSubscription;
  final _profileDataNotifier = ValueNotifier<List<_AnalyticsItemInfo>>(
    <_AnalyticsItemInfo>[],
  );
  final newProfileDataCountNotifier = ValueNotifier<int>(0);
  bool _autoScrollToEnd = true;

  bool get autoScrollToEnd => _autoScrollToEnd;
  set autoScrollToEnd(bool value) {
    if (value == _autoScrollToEnd) return;
    _autoScrollToEnd = value;
    if (value) {
      newProfileDataCountNotifier.value = 0;
    }
  }

  double get lastScrollOffset {
    final totalContentHeight = _profileDataNotifier.value.fold<double>(
      0.0,
      (sum, item) => sum + item.height,
    );
    if (!_scrollController.hasClients ||
        totalContentHeight <= _scrollController.position.extentInside) {
      return 0.0;
    }
    return totalContentHeight - _scrollController.position.extentInside;
  }

  void _ensureLastItemVisible() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        lastScrollOffset,
        duration: Duration(milliseconds: 160),
        curve: Curves.easeInOut,
      );
    }
    autoScrollToEnd = true;
  }

  void _onExpandedChange(int index, bool expanded, double height) {
    if (index == _profileDataNotifier.value.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _ensureLastItemVisible();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        autoScrollToEnd = _scrollController.position.extentAfter == 0;
      });
    }
    _profileDataNotifier.value[index]
      ..expanded = expanded
      ..height = height;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _profileDataNotifier.value = _wrapWithAnalyticsItemInfo(
      AnalyticsProfiler.instance.getProfileData() ?? [],
    );
    _scrollController = ScrollController(
      initialScrollOffset: _profileDataNotifier.value.fold(
        0.0,
        (previousValue, element) => previousValue + element.height,
      ),
    );
    _profileDataSubscription = AnalyticsProfiler.instance
        .getProfileDataStream()
        .listen(_onProfileDataChange);
  }

  List<_AnalyticsItemInfo> _wrapWithAnalyticsItemInfo(
    List<AnalyticsProfileData> profileData,
  ) {
    List<_AnalyticsItemInfo> result = [];
    final currentValue = _profileDataNotifier.value;
    for (int i = 0; i < profileData.length && i < currentValue.length; i++) {
      result.add(
        _AnalyticsItemInfo(
          data: profileData[i],
          expanded: currentValue[i].expanded,
          height: currentValue[i].height,
        ),
      );
    }
    for (int i = currentValue.length; i < profileData.length; i++) {
      result.add(_AnalyticsItemInfo(data: profileData[i]));
    }
    return result;
  }

  void _onProfileDataChange(List<AnalyticsProfileData> profileData) {
    final dataCountDiff =
        profileData.length - _profileDataNotifier.value.length;
    _profileDataNotifier.value = _wrapWithAnalyticsItemInfo(profileData);

    if ((autoScrollToEnd && _scrollController.hasClients == true) ||
        profileData.isEmpty) {
      _ensureLastItemVisible();
    } else if (!autoScrollToEnd) {
      if (dataCountDiff > 0) {
        newProfileDataCountNotifier.value += dataCountDiff;
      } else {
        newProfileDataCountNotifier.value = 0;
      }
    }
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
    _profileDataSubscription?.cancel();
    _profileDataNotifier.dispose();
    _scrollController.dispose();
    newProfileDataCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppDevToolsScaffold(
      appBar: InAppDevToolsAppBar(
        customActions: [
          IconButton(
            tooltip: 'Delete analytics logs',
            onPressed: AnalyticsProfiler.instance.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<SizeChangedLayoutNotification>(
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
                child: ValueListenableBuilder<List<_AnalyticsItemInfo>>(
                  valueListenable: _profileDataNotifier,
                  builder: (context, itemInfos, _) {
                    if (itemInfos.isEmpty) {
                      return const Center(
                        child: Text(
                          'Empty',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemExtentBuilder: (index, _) {
                          return index >= itemInfos.length
                              ? null
                              : itemInfos[index].height;
                        },
                        itemCount: itemInfos.length,
                        itemBuilder: (context, index) {
                          return _AnalyticsProfileWidget(
                            hideTopDivider: index == 0,
                            hideBottomDivider: index == itemInfos.length - 1,
                            itemInfo: itemInfos[index],
                            onExpandStateChange: (expanded, height) =>
                                _onExpandedChange(index, expanded, height),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: ValueListenableBuilder(
              valueListenable: newProfileDataCountNotifier,
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
      ),
    );
  }
}

class _AnalyticsProfileWidget extends StatefulWidget {
  const _AnalyticsProfileWidget({
    required this.onExpandStateChange,
    required this.itemInfo,
    this.hideTopDivider = false,
    this.hideBottomDivider = false,
  });
  final void Function(bool expanded, double height) onExpandStateChange;
  final _AnalyticsItemInfo itemInfo;
  final bool hideTopDivider;
  final bool hideBottomDivider;

  @override
  State<_AnalyticsProfileWidget> createState() =>
      _AnalyticsProfileWidgetState();
}

class _AnalyticsProfileWidgetState extends State<_AnalyticsProfileWidget> {
  String? _stringContent;
  late bool _expanded = widget.itemInfo.expanded;
  GlobalKey? _contentKey;
  ScrollController? _scrollController;

  bool get expanded => _stringContent != null && _expanded;
  @override
  void initState() {
    super.initState();
    if (_expanded) {
      _stringContent = getContentData();
    }
  }

  String getContentData() {
    String getParametersContent(Map<String, Object?>? parameters) {
      String parametersString;
      try {
        parametersString = JsonEncoder.withIndent('\t').convert(parameters);
      } catch (e) {
        parametersString = parameters.toString();
      }
      return parametersString;
    }

    String getUserPropertyContent(String name, Object? value) {
      String propertyString;
      try {
        propertyString = JsonEncoder.withIndent('\t').convert({name: value});
      } catch (e) {
        propertyString = {name: value}.toString();
      }
      return propertyString;
    }

    final data = widget.itemInfo.data;
    return switch (data) {
      Event() => getParametersContent(data.parameters),
      ScreenView() => getParametersContent(data.parameters),
      GlobalParameters() => getParametersContent(data.parameters),
      UserId() => jsonEncode(data.userId),
      UserProperty() => getUserPropertyContent(data.name, data.value),
    };
  }

  void showData() {
    _contentKey = GlobalKey();
    _scrollController ??= ScrollController();
    _stringContent = getContentData();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _expanded = true;
      final renderBox =
          _contentKey!.currentContext!.findRenderObject() as RenderBox;
      final size = renderBox.size;
      widget.onExpandStateChange(
        true,
        (size.height + _kAnalyticsRowHeight + _kDividerHeight * 2).clamp(
          _kAnalyticsRowHeight,
          240,
        ),
      );
    });
  }

  void hideData() {
    _expanded = false;
    _contentKey = null;
    setState(() {});
  }

  void _resetDataState() {
    if (!_expanded) {
      _stringContent = null;
      widget.onExpandStateChange(
        false,
        _kAnalyticsRowHeight + _kDividerHeight * 2,
      );
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    const contentAlignment = Alignment(numerator * part - 1, -1);
    Widget contentChild;
    Color color;
    String title;

    // Accents: slightly higher chroma than before for clearer contrast on dark UIs.
    const accentEvent = Color(0xFFC49A6A); // warm amber
    const accentScreen = Color(0xFF5AA3AD); // teal / cyan
    const accentGlobal = Color(0xFF9E8FBD); // lavender
    const accentUserId = Color(0xFF6B9ED8); // steel blue
    const accentUserProp = Color(0xFF72B57A); // sage green

    final data = widget.itemInfo.data;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    IconData iconData;
    switch (data) {
      case Event():
        title = data.name;
        color = accentEvent;
        iconData = Icons.touch_app;
        break;
      case ScreenView():
        title = data.screenName;
        color = accentScreen;
        iconData = Icons.smartphone;
        break;
      case GlobalParameters():
        title = data.parameters.toString();
        color = accentGlobal;
        iconData = Icons.public;
        break;
      case UserId():
        title = data.userId.toString();
        color = accentUserId;
        iconData = Icons.person;
        break;
      case UserProperty():
        title = "${data.name}=${data.value}";
        color = accentUserProp;
        iconData = Icons.badge;
        break;
    }

    if (_stringContent case final String contentText) {
      contentChild = OverflowBox(
        maxWidth: width - 24,
        minWidth: width - 24,
        minHeight: widget.itemInfo.height,
        maxHeight: widget.itemInfo.height,
        alignment: contentAlignment,
        fit: OverflowBoxFit.deferToChild,
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, _kAnalyticsRowHeight, 0, 0),
          // padding: EdgeInsets.zero,
          child: Scrollbar(
            thumbVisibility: true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                key: _contentKey,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  contentText,
                  style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      contentChild = const SizedBox.shrink();
    }

    return Stack(
      alignment: contentAlignment,
      children: [
        if (widget.hideTopDivider)
          SizedBox(
            width: _kAnalyticsRowHeight,
            child: Center(
              child: VerticalDivider(
                thickness: 2,
                indent: _kAnalyticsRowHeight / 2,
              ),
            ),
          )
        else if (widget.hideBottomDivider)
          SizedBox(
            width: _kAnalyticsRowHeight,
            child: Center(
              child: VerticalDivider(
                thickness: 2,
                endIndent: _kAnalyticsRowHeight / 2,
              ),
            ),
          )
        else
          SizedBox(
            width: _kAnalyticsRowHeight,
            child: Center(child: VerticalDivider(thickness: 2)),
          ),
        Padding(
          // padding: EdgeInsets.zero,
          padding: EdgeInsets.fromLTRB(0, _kDividerHeight, 0, _kDividerHeight),
          child: AnimatedContainer(
            // margin: EdgeInsets.fromLTRB(12, 0, 12, 0),
            onEnd: _resetDataState,
            curve: Curves.easeInOut,
            duration: Duration(milliseconds: 200),
            constraints: expanded
                ? BoxConstraints(
                    minWidth: _kAnalyticsRowHeight,
                    minHeight: _kAnalyticsRowHeight,
                    maxWidth: width,
                    maxHeight: 240,
                  )
                : BoxConstraints.tightFor(
                    width: _kAnalyticsRowHeight,
                    height: _kAnalyticsRowHeight,
                  ),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(color: color, width: 1.25),
              borderRadius: BorderRadius.circular(expanded ? 10 : 100),
            ),
            child: contentChild,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: expanded ? hideData : showData,
          child: Padding(
            // padding: EdgeInsets.zero,
            padding: EdgeInsets.fromLTRB(
              0,
              _kDividerHeight,
              0,
              _kDividerHeight,
            ),
            child: _TileHeader(
              dateTime: widget.itemInfo.data.loggedAt,
              title: title,
              showDateTime: widget.itemInfo.data.canShowDateTime || expanded,
              color: expanded ? Colors.transparent : color,
              icon: Icon(iconData, color: expanded ? color : bgColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _TileHeader extends StatelessWidget {
  const _TileHeader({
    required this.title,
    required this.showDateTime,
    required this.color,
    required this.icon,
    required this.dateTime,
  });
  final DateTime dateTime;
  final String title;
  final bool showDateTime;
  final Color color;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: title,
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: numerator,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                showDateTime ? _formatLoggedAt(dateTime) : '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(100),
            ),
            child: SizedBox.square(
              dimension: _kAnalyticsRowHeight,
              child: icon,
            ),
          ),
          Expanded(
            flex: denominator,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatLoggedAt(DateTime loggedAt) {
  return DateFormat('HH:mm:ss').format(loggedAt);
}
