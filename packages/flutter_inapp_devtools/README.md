Monitor all network requests, analytics events, and debugging logs in real-time, directly inside your app.

## 🚀 Quickstart
```dart
void main() {
  NetworkTool.ensureInitialized();
  //...your code here
  runApp(InAppDevTools(child: MyApp()));
}
```

## 🔥 Features
### 🌐 Network Tool
<img src="https://raw.githubusercontent.com/shashikantdurge/inapp_devtools/refs/heads/master/packages/flutter_inapp_devtools/assets/network_tool_use.gif" alt="Network Tool" width="360" />

### 📊 Analytics Tool
<img src="https://raw.githubusercontent.com/shashikantdurge/inapp_devtools/refs/heads/master/packages/flutter_inapp_devtools/assets/analytics_tool_use.gif" alt="Analytics Tool" height="360" />

###  Logging Tool
<img src="https://raw.githubusercontent.com/shashikantdurge/inapp_devtools/refs/heads/master/packages/flutter_inapp_devtools/assets/logging_tool_use.gif" alt="Logging Tool" height="360" />




## Additional information
### Custom Tool
You can build your own custom tool and pass it to `InAppDevTools` widget.
Use cases could be - switching between dev/prod environments, performing some action to reproduce some testing scenario etc.

### DataPreviewExtension (for NetworkTool)
The default preview supports rendering plain text and image data. You can also customize how data is displayed in the NetworkTool detailed view.

There are packages available for rendering specific data types:

HTML — [iad_html_data_preview](https://pub.dev/packages/iad_html_data_preview)

JSON — [iad_json_data_preview](https://pub.dev/packages/iad_json_data_preview)

```dart
InAppDevTools(
  tools: [
    NetworkTool(
      dataPreviewExtensions: [
        IadJsonDataPreview(),
        IadHtmlDataPreview(),
      ],
    ),
    const LoggingTool(),
    const AnalyticsTool(),
  ],
  child: MyApp(),
)
```

## Roadmap
1. Copy feature improvements
2. Filters improvement - Control what data to be seen in the list
3. Stats - Data usage, Analytics count etc
4. Support for CronetClient and CupertinoClient based on demand (NetworkTool)
5. Want us to prioritize something that improves your or your team’s productivity? Raise a request on GitHub Issues — we’d be happy to solve it.

