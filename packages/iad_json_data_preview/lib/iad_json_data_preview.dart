import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:flutter_pretty_json/flutter_pretty_json.dart';

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
  Widget buildPreview(String data) {
    return PrettyJson(
      encodedJson: data,
      expandDepth: expandDepth,
      expanded: expanded,
    );
  }

  @override
  VoidCallback? copyContentCallback(String data) {
    return () {
      final content = JsonEncoder.withIndent('\t').convert(jsonDecode(data));
      Clipboard.setData(ClipboardData(text: content));
    };
  }
}
