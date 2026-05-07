import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:flutter_pretty_json/flutter_pretty_json.dart';

class IadJsonDataPreview extends DataPreviewExtension<String> {
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
    return PrettyJson(encodedJson: data);
  }

  @override
  VoidCallback? copyContentCallback(String data) {
    return () {
      final content = JsonEncoder.withIndent('\t').convert(jsonDecode(data));
      debugPrint('Copy content: $content');
      Clipboard.setData(ClipboardData(text: content));
    };
  }
}
