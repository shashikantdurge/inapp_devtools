import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inapp_devtools/inapp_devtools.dart';

class IadImageDataPreview extends DataPreviewExtension {
  @override
  Widget buildPreview(DataContext dataContext) {
    return _ImagePreviewWidget(dataContext: dataContext);
  }

  @override
  String? copyableText(DataContext dataContext) {
    return null;
  }

  @override
  bool isSupported(ContentType contentType) {
    return contentType.primaryType == 'image';
  }
}

class _ImagePreviewWidget extends StatefulWidget {
  final DataContext dataContext;

  const _ImagePreviewWidget({required this.dataContext});

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
    final bytes = Uint8List.fromList(widget.dataContext.data);
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
          infoRow('Format', widget.dataContext.contentType.mimeType),
          infoRow('Size', imageSizeStr),
          infoRow('Dimensions', dimensions != null ? '${dimensions?.$1} x ${dimensions?.$2}' : ''),
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
