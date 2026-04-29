import 'dart:io';

import 'package:flutter/material.dart';

abstract class DataPreviewExtension {
  bool isSupported(ContentType contentType);
  Widget buildPreview(DataContext dataContext);
  String? copyableText(DataContext dataContext);
}

class DataContext {
  final List<int> data;
  final ContentType contentType;

  DataContext({required this.data, required this.contentType});
}
