import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:intl/intl.dart';

import 'analytics_profile_data.dart';

const _kAnalyticsItemHeight = 36.0;
const _kAnalyticsParamsHeight = 120.0;
const _kDividerHeight = 6.0;
const numerator = 1;
const denominator = 3;
const part = 2 / (denominator + numerator);

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
  late final Stream<List<AnalyticsProfileData>> _itemsStream;

  @override
  void initState() {
    super.initState();
    _itemsStream = AnalyticsProfiler.instance.getProfileDataStream();
  }

  List<AnalyticsProfileData> _getItems() {
    return AnalyticsProfiler.instance.getProfileData() ?? [];
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
      body: InAppDevToolsScrollView<AnalyticsProfileData>(
        padding: EdgeInsets.only(bottom: 16),
        getItems: _getItems,
        itemsStream: _itemsStream,
        separatorBuilder: (context, index, animation) {
          return const SizedBox.shrink();
        },
        itemBuilder: (context, itemInfo) {
          return _AnalyticsProfileWidget(
            key: ValueKey(itemInfo.item),
            profileData: itemInfo.item,
            hideBottomDivider: itemInfo.isLast,
          );
        },
      ),
    );
  }
}

class _AnalyticsProfileWidget extends StatefulWidget {
  const _AnalyticsProfileWidget({
    super.key,
    required this.profileData,
    this.hideBottomDivider = false,
  });
  final AnalyticsProfileData profileData;
  final bool hideBottomDivider;

  @override
  State<_AnalyticsProfileWidget> createState() =>
      _AnalyticsProfileWidgetState();
}

class _AnalyticsProfileWidgetState extends State<_AnalyticsProfileWidget> {
  String? _stringContent;
  late bool _expanded = false;

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

    final data = widget.profileData;
    return switch (data) {
      Event() => getParametersContent(data.parameters),
      ScreenView() => getParametersContent(data.parameters),
      GlobalParameters() => getParametersContent(data.parameters),
      UserId() => jsonEncode(data.userId),
      UserProperty() => getUserPropertyContent(data.name, data.value),
    };
  }

  void showData() {
    _expanded = true;
    _stringContent = getContentData();
    setState(() {});
  }

  void hideData() {
    _expanded = false;
    setState(() {});
  }

  void _resetDataState() {
    if (!_expanded) {
      _stringContent = null;
      setState(() {});
    }
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

    final data = widget.profileData;
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
        maxWidth: width,
        minWidth: width,
        minHeight: _kAnalyticsItemHeight,
        maxHeight: _kAnalyticsParamsHeight + _kAnalyticsItemHeight,
        alignment: contentAlignment,
        fit: OverflowBoxFit.deferToChild,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, _kAnalyticsItemHeight, 8, 8),
          child: CodeBlockBox(
            text: contentText,
            maxHeight: _kAnalyticsParamsHeight,
          ),
        ),
      );
    } else {
      contentChild = const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: contentAlignment,
          child: SizedBox(
            width: _kAnalyticsItemHeight,
            height: _kDividerHeight,
            child: VerticalDivider(thickness: 2),
          ),
        ),
        Stack(
          alignment: contentAlignment,
          children: [
            AnimatedContainer(
              onEnd: _resetDataState,
              curve: Curves.easeInOut,
              duration: Duration(milliseconds: 200),
              constraints: expanded
                  ? BoxConstraints(
                      minWidth: _kAnalyticsItemHeight,
                      minHeight: _kAnalyticsItemHeight,
                      maxWidth: width,
                      maxHeight: 240,
                    )
                  : BoxConstraints.tightFor(
                      width: _kAnalyticsItemHeight,
                      height: _kAnalyticsItemHeight,
                    ),
              clipBehavior: Clip.hardEdge,
              foregroundDecoration: BoxDecoration(
                border: Border.all(color: color, width: 1.25),
                borderRadius: BorderRadius.circular(expanded ? 10 : 100),
              ),
              decoration: BoxDecoration(
                color: expanded
                    ? Colors.black
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(expanded ? 10 : 100),
              ),
              child: contentChild,
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: expanded ? hideData : showData,
              child: _TileHeader(
                dateTime: widget.profileData.loggedAt,
                title: title,
                showDateTime: widget.profileData.canShowDateTime || expanded,
                color: expanded ? Colors.transparent : color,
                icon: Icon(iconData, color: expanded ? color : bgColor),
              ),
            ),
          ],
        ),
        if (!widget.hideBottomDivider)
          Align(
            alignment: contentAlignment,
            child: SizedBox(
              width: _kAnalyticsItemHeight,
              height: _kDividerHeight,
              child: VerticalDivider(thickness: 2),
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
              dimension: _kAnalyticsItemHeight,
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
