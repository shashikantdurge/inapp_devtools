import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';

class IadImageDataPreview extends DataPreviewExtension<ImageDataContext> {
  @override
  ImageDataContext? mayInitialize(DataContext dataContext) {
    if (dataContext.contentType case ContentType(
      primaryType: 'image',
      mimeType: String mimeType,
    )) {
      return ImageDataContext(
        data: Uint8List.fromList(dataContext.data),
        imageFormat: mimeType,
      );
    }
    return null;
  }

  @override
  Widget buildPreview(ImageDataContext data) {
    return _ImagePreviewWidget(data: data);
  }
}

class ImageDataContext {
  final Uint8List data;
  final String imageFormat;

  ImageDataContext({required this.data, required this.imageFormat});
}

class _ImagePreviewWidget extends StatefulWidget {
  final ImageDataContext data;

  const _ImagePreviewWidget({required this.data});

  @override
  State<_ImagePreviewWidget> createState() => __ImagePreviewWidgetState();
}

class __ImagePreviewWidgetState extends State<_ImagePreviewWidget> {
  (int width, int height)? dimensions;
  late String imageSizeStr;
  late Image image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    final bytes = widget.data.data;
    image = Image.memory(bytes);
    imageSizeStr = _readableSize(bytes.length);
    image.image
        .resolve(ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            setState(() {
              dimensions = (info.image.width, info.image.height);
            });
          }),
        );
  }

  Widget infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: Text(label)),
        ),
        Text("  :  "),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: Text(value)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(24), child: image),
          Divider(),
          infoRow('Format', widget.data.imageFormat),
          infoRow('Size', imageSizeStr),
          infoRow(
            'Dimensions',
            dimensions != null ? '${dimensions?.$1} x ${dimensions?.$2}' : '',
          ),
        ],
      ),
    );
  }
}

String _readableSize(int size) {
  if (size < 1024) {
    return '$size B';
  }
  if (size < 1024 * 1024) {
    return '${(size / 1024).toStringAsFixed(2)} KB';
  }
  return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
}
