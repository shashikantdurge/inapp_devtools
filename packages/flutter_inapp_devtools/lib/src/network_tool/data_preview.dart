import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CopyContentCallback<T> = Object? Function();

@immutable
abstract class DataPreviewExtension<T> {
  T? mayInitialize(DataContext dataContext);
  Widget buildPreview(BuildContext context, T data);
  CopyContentCallback<T>? copyContentCallback(T data) => null;
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
  Widget buildPreview(BuildContext context, DefaultPreviewExtensionData data) {
    Widget child = switch (data) {
      DefaultTextPreviewExtensionData() => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(data.text),
      ),
      DefaultImagePreviewExtensionData() => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Image.memory(data.image, fit: BoxFit.contain),
      ),
    };
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverToBoxAdapter(child: child),
      ],
    );
  }

  @override
  CopyContentCallback<DefaultPreviewExtensionData>? copyContentCallback(
    DefaultPreviewExtensionData data,
  ) {
    switch (data) {
      case DefaultTextPreviewExtensionData():
        return () {
          return data.text;
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
