import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:flutter_pretty_json/flutter_pretty_json.dart';

class IadJsonDataPreview extends DataPreviewExtension {
  @override
  Widget buildPreview(DataContext dataContext) {
    return _JsonDataPreview(encodedJson: utf8.decode(dataContext.data));
  }

  @override
  String? copyableText(DataContext dataContext) {
    final jsonEncoder = JsonEncoder.withIndent('\t');
    return jsonEncoder.convert(jsonDecode(utf8.decode(dataContext.data)));
  }

  @override
  bool isSupported(ContentType contentType) {
    return contentType.mimeType == 'application/json';
  }
}

class _JsonDataPreview extends StatefulWidget {
  final String encodedJson;
  const _JsonDataPreview({required this.encodedJson});
  @override
  State<_JsonDataPreview> createState() => __JsonDataPreviewState();
}

class __JsonDataPreviewState extends State<_JsonDataPreview> {
  @override
  Widget build(BuildContext context) {
    return PrettyJson(encodedJson: widget.encodedJson);
  }
}
