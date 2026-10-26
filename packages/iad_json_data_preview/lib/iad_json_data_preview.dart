import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_inapp_devtools/flutter_inapp_devtools.dart';
import 'package:flutter_pretty_json/flutter_pretty_json.dart' as pj;

class IadJsonDataPreview extends DataPreviewExtension<String> {
  /// The depth to expand the tree. Defaults to null.
  /// If the [expanded] is set to false, this will be ignored.
  final int? expandDepth;

  /// Whether the tree is expanded. Defaults to true.
  /// For custom expand depth, check [expandDepth].
  final bool expanded;

  IadJsonDataPreview({this.expandDepth, this.expanded = true});

  @override
  String? mayInitialize(DataContext dataContext) {
    if (dataContext.contentType case ContentType(
      mimeType: 'application/json',
    )) {
      return utf8.decode(dataContext.data);
    }
    return null;
  }

  @override
  Widget buildPreview(BuildContext context, String data) {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverFillRemaining(
          child: pj.PrettyJson(
            encodedJson: data,
            expandDepth: expandDepth,
            expanded: expanded,
            copyContentCallback: (data) {
              InAppDevTools.of(context).copyDataCallback(data);
            },
            verticalDetails: ScrollableDetails.vertical(
              controller: PrimaryScrollController.maybeOf(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  CopyContentCallback<String>? copyContentCallback(String data) {
    return () {
      return JsonEncoder.withIndent('\t').convert(jsonDecode(data));
    };
  }
}
