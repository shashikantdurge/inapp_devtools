import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:inapp_devtools/inapp_devtools.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IadHtmlDataPreview extends DataPreviewExtension<String> {
  @override
  String? mayInitialize(DataContext dataContext) {
    if (dataContext.contentType case ContentType(mimeType: 'text/html')) {
      return utf8.decode(dataContext.data);
    }
    return null;
  }

  @override
  Widget buildPreview(String data) {
    return _HtmlPreviewWidget(data: data);
  }

  @override
  VoidCallback? copyContentCallback(String data) {
    return () {
      Clipboard.setData(ClipboardData(text: data));
    };
  }
}

class _HtmlPreviewWidget extends StatefulWidget {
  final String data;
  const _HtmlPreviewWidget({required this.data});
  @override
  State<_HtmlPreviewWidget> createState() => __HtmlPreviewWidgetState();
}

class __HtmlPreviewWidgetState extends State<_HtmlPreviewWidget> {
  late WebViewController controller;
  final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers = {
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };
  late final String _htmlWithImageFallback;

  @override
  void initState() {
    super.initState();
    _htmlWithImageFallback = _injectImageErrorFallback(widget.data);
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..loadHtmlString(_htmlWithImageFallback);
  }

  String _injectImageErrorFallback(String html) {
    const imageFallbackScript = '''
<script>
(() => {
  const markBroken = (img) => {
    // Keep the failed image element visible (broken-image UI),
    // but suppress fallback text like alt/title.
    img.alt = '';
    img.removeAttribute('alt');
    img.removeAttribute('title');
    img.setAttribute('aria-label', '');
  };

  const attachHandler = (img) => {
    img.onerror = () => markBroken(img);
  };

  const bindAllImages = () => {
    document.querySelectorAll('img').forEach((img) => {
      attachHandler(img);
      if (img.complete && img.naturalWidth === 0) {
        markBroken(img);
      }
    });
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bindAllImages, { once: true });
  } else {
    bindAllImages();
  }
})();
</script>
''';

    if (html.contains('</head>')) {
      return html.replaceFirst('</head>', '$imageFallbackScript</head>');
    }
    if (html.contains('<body')) {
      return html.replaceFirst(
        RegExp(r'(<body[^>]*>)'),
        r'$1$imageFallbackScript',
      );
    }
    return '$imageFallbackScript$html';
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: controller,
      gestureRecognizers: _gestureRecognizers,
    );
  }
}
