A Flutter widget for rendering JSON as an expandable tree with syntax highlighting.

## Features

- Expand and collapse nested JSON objects and arrays.
- Syntax highlighting for keys, strings, numbers, booleans, and null values.
- Long-press context menu actions:
  - Copy value
  - Copy name
  - Copy property path
- Light and dark themes through `PrettyJsonTheme` ThemeExtension.

## Example

```dart
PrettyJson(
  encodedJson: '{"stringValue": "Hello, JSON tree!",emptyString": "","integerValue": 42, ... }',
  expanded: true,
  expandDepth: 1,
)
```


## Example app

A complete runnable sample is available in `example/lib/main.dart`.

## Contributing and support
- Open issues or feature requests in the repository issue tracker.
