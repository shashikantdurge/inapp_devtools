Monitor network requests, analytics events, and logs inside your app.

## 🚀 Quickstart
```dart
void main() {
  NetworkTool.ensureInitialized();
  //...your code here
  runApp(InAppDevTools(child: MyApp()));
}

//That's all for quickstart
```

## 🔥 Tools
This package comes with 3 tools out of the box.
<br/>

## 1. 🌐 Network Tool
Monitor http network calls. No additional setup required.

What details are shown?
- Request URL, method, headers, body
- Response status, headers, body, size and time taken

By default the body is rendered as plain text or image.

You can customize how the body data is rendered by passing a list of `DataPreviewExtension`s to the `NetworkTool`.
Some extensions are provided for common data types:
- JSON Beautifier - [iad_json_data_preview](https://pub.dev/packages/iad_json_data_preview)
- HTML Viewer - [iad_html_data_preview](https://pub.dev/packages/iad_html_data_preview)

Usage:

```dart
import 'package:iad_json_data_preview/iad_json_data_preview.dart';
import 'package:iad_html_data_preview/iad_html_data_preview.dart';

//...
void main() {
  NetworkTool.ensureInitialized();
  //...your code here
  runApp(InAppDevTools(
    tools: [
      NetworkTool(
        dataPreviewExtensions: [
          IadJsonDataPreview(),
          IadHtmlDataPreview(),
        ],
      ),
      //...other tools here
    ],
    child: MyApp()));
}
```

<img src="https://raw.githubusercontent.com/shashikantdurge/inapp_devtools/refs/heads/master/packages/flutter_inapp_devtools/assets/network.jpeg" alt="Network Tool" />
<br/>

## 2. 📋 Logging Tool
Monitor logs logged by [package:logging](https://pub.dev/packages/logging).
How to log?
```dart
final log = Logger('PaymentService');
log.shout("Payment failed");

//Methods supported:
//- `shout`
//- `severe`
//- `warning`
//- `info`
//- `config`
//- `fine`
//- `finer`
//- `finest`
```

<img src="https://raw.githubusercontent.com/shashikantdurge/inapp_devtools/refs/heads/master/packages/flutter_inapp_devtools/assets/logging.jpeg" alt="Logging Tool" />
<br/>

## 3. 📊 Analytics Tool
Monitor analytics events.

```dart
//Usage:
AnalyticsProfiler.instance.logEvent('purchase_clicked');

//Methods supported:
//- `logEvent`
//- `logScreenView`
//- `setUserId`
//- `setUserProperty`
//- `setGlobalParameters`
```

<img src="https://raw.githubusercontent.com/shashikantdurge/inapp_devtools/refs/heads/master/packages/flutter_inapp_devtools/assets/analytics.jpeg" alt="Analytics Tool" />
<br/>

## N. 🔧 Custom Tool
You can build your own custom tool and pass it to `InAppDevTools` widget.
Use cases could be - switching between dev/prod environments, performing some action to reproduce some testing scenario etc.

## Limitations
- Network logging - Only HTTP network calls are supported.

## Roadmap
1. Copy feature improvements
2. Filters improvement - Control what data to be seen in the list
3. Stats - Data usage, Analytics count etc
4. Support for CronetClient and CupertinoClient based on demand (NetworkTool)
5. Want us to prioritize something that improves your or your team’s productivity? [Raise a request on GitHub Issues](https://github.com/shashikantdurge/inapp_devtools/issues) — we’d be happy to solve it.

