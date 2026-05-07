import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
abstract class DataPreviewExtension<T> {
  T? mayInitialize(DataContext dataContext);
  Widget buildPreview(T data);
  VoidCallback? copyContentCallback(T data) => null;
}

class DataContext {
  final List<int> data;
  final ContentType? contentType;

  DataContext({required this.data, required this.contentType});
}

class DefaultDataPreviewExtension
    extends DataPreviewExtension<DefaultPreviewExtensionData> {
  @override
  DefaultPreviewExtensionData? mayInitialize(DataContext dataContext) {
    try {
      if (dataContext.contentType case ContentType(primaryType: 'image')) {
        return DefaultImagePreviewExtensionData(
          image: Uint8List.fromList(dataContext.data),
        );
      }
      final text = utf8.decode(dataContext.data);
      try {
        final json = jsonDecode(text);
        final jsonString = JsonEncoder.withIndent('\t').convert(json);
        return DefaultTextPreviewExtensionData(text: jsonString);
      } catch (e) {
        return DefaultTextPreviewExtensionData(text: text);
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget buildPreview(DefaultPreviewExtensionData data) {
    switch (data) {
      case DefaultTextPreviewExtensionData():
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Text(data.text),
        );
      case DefaultImagePreviewExtensionData():
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Image.memory(data.image, fit: BoxFit.contain),
        );
    }
  }

  @override
  VoidCallback? copyContentCallback(DefaultPreviewExtensionData data) {
    switch (data) {
      case DefaultTextPreviewExtensionData():
        return () {
          Clipboard.setData(ClipboardData(text: data.text));
        };
      case DefaultImagePreviewExtensionData():
        return null;
    }
  }
}

sealed class DefaultPreviewExtensionData {}

class DefaultTextPreviewExtensionData extends DefaultPreviewExtensionData {
  final String text;
  DefaultTextPreviewExtensionData({required this.text});
}

class DefaultImagePreviewExtensionData extends DefaultPreviewExtensionData {
  final Uint8List image;
  DefaultImagePreviewExtensionData({required this.image});
}
