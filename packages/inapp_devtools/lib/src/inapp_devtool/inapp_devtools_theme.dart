import 'package:flutter/material.dart';

// Postman-inspired dark palette (workspace surfaces + orange accent).
// Reference: dark bg ~#1E1E1E, surfaces ~#2D2D2D, accent ~#FF6C37, borders ~#404040.

/// Styling for [InAppDevTools] chrome: scaffold, app bar, picker, and panel accents.
@immutable
class InAppDevToolsThemeData {
  const InAppDevToolsThemeData({
    required this.scaffoldBackgroundColor,
    required this.appBarBackgroundColor,
    required this.appBarToolSelectorBackgroundColor,
    required this.appBarToolSelectorBorderColor,
    required this.appBarMenuUnderlineColor,
    required this.appBarLabelStyle,
    required this.appBarIconColor,
    required this.pickerBottomBorderColor,
    required this.pickerItemLabelStyle,
    required this.pickerIconColor,
    required this.pickerListDividerColor,
    required this.panelBorderColor,
    required this.minimizedFabBackgroundColor,
    required this.minimizedFabIconColor,
  });

  /// [InAppDevToolsScaffold] body background.
  final Color scaffoldBackgroundColor;

  /// App bar and picker chrome fill.
  final Color appBarBackgroundColor;

  /// Flat tool-selector control: slightly lifted from [appBarBackgroundColor].
  final Color appBarToolSelectorBackgroundColor;

  /// Hairline border around the tool selector.
  final Color appBarToolSelectorBorderColor;

  /// App bar accent (e.g. focus highlights); tool selector uses [appBarToolSelectorBorderColor].
  final Color appBarMenuUnderlineColor;

  /// Tool title and picker row labels in the app bar region.
  final TextStyle appBarLabelStyle;

  /// Close, menu arrow, and picker leading icons.
  final Color appBarIconColor;

  /// Bottom border of the horizontal tool picker strip.
  final Color pickerBottomBorderColor;

  /// Labels in the horizontal tool list.
  final TextStyle pickerItemLabelStyle;

  /// Leading close icon in the picker row.
  final Color pickerIconColor;

  /// [VerticalDivider] between picker items.
  final Color pickerListDividerColor;

  /// Border around the panel in windowed / maximized modes.
  final Color panelBorderColor;

  /// Minimized floating button fill (when [InAppDevTools.color] is null).
  final Color minimizedFabBackgroundColor;

  /// [Icons.developer_mode] on the minimized button.
  final Color minimizedFabIconColor;

  /// Default dark styling aligned with Postman’s dark UI (surfaces + orange accent).
  static const InAppDevToolsThemeData dark = InAppDevToolsThemeData(
    scaffoldBackgroundColor: Color(0xFF1E1E1E),
    appBarBackgroundColor: Color(0xFF2D2D2D),
    appBarToolSelectorBackgroundColor: Color(0xFF333333),
    appBarToolSelectorBorderColor: Color(0xFF404040),
    appBarMenuUnderlineColor: Color(0xFFFF6C37),
    appBarLabelStyle: TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    appBarIconColor: Color(0xFFBDBDBD),
    pickerBottomBorderColor: Color(0xFF404040),
    pickerItemLabelStyle: TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 14,
    ),
    pickerIconColor: Color(0xFF9E9E9E),
    pickerListDividerColor: Color(0xFF404040),
    panelBorderColor: Color(0xFF404040),
    minimizedFabBackgroundColor: Color(0xFFFF6C37),
    minimizedFabIconColor: Color(0xFFFFFFFF),
  );

  InAppDevToolsThemeData copyWith({
    Color? scaffoldBackgroundColor,
    Color? appBarBackgroundColor,
    Color? appBarToolSelectorBackgroundColor,
    Color? appBarToolSelectorBorderColor,
    Color? appBarMenuUnderlineColor,
    TextStyle? appBarLabelStyle,
    Color? appBarIconColor,
    Color? pickerBottomBorderColor,
    TextStyle? pickerItemLabelStyle,
    Color? pickerIconColor,
    Color? pickerListDividerColor,
    Color? panelBorderColor,
    Color? minimizedFabBackgroundColor,
    Color? minimizedFabIconColor,
  }) {
    return InAppDevToolsThemeData(
      scaffoldBackgroundColor:
          scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
      appBarBackgroundColor:
          appBarBackgroundColor ?? this.appBarBackgroundColor,
      appBarToolSelectorBackgroundColor: appBarToolSelectorBackgroundColor ??
          this.appBarToolSelectorBackgroundColor,
      appBarToolSelectorBorderColor:
          appBarToolSelectorBorderColor ?? this.appBarToolSelectorBorderColor,
      appBarMenuUnderlineColor:
          appBarMenuUnderlineColor ?? this.appBarMenuUnderlineColor,
      appBarLabelStyle: appBarLabelStyle ?? this.appBarLabelStyle,
      appBarIconColor: appBarIconColor ?? this.appBarIconColor,
      pickerBottomBorderColor:
          pickerBottomBorderColor ?? this.pickerBottomBorderColor,
      pickerItemLabelStyle: pickerItemLabelStyle ?? this.pickerItemLabelStyle,
      pickerIconColor: pickerIconColor ?? this.pickerIconColor,
      pickerListDividerColor:
          pickerListDividerColor ?? this.pickerListDividerColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      minimizedFabBackgroundColor:
          minimizedFabBackgroundColor ?? this.minimizedFabBackgroundColor,
      minimizedFabIconColor: minimizedFabIconColor ?? this.minimizedFabIconColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InAppDevToolsThemeData &&
        scaffoldBackgroundColor == other.scaffoldBackgroundColor &&
        appBarBackgroundColor == other.appBarBackgroundColor &&
        appBarToolSelectorBackgroundColor ==
            other.appBarToolSelectorBackgroundColor &&
        appBarToolSelectorBorderColor == other.appBarToolSelectorBorderColor &&
        appBarMenuUnderlineColor == other.appBarMenuUnderlineColor &&
        appBarLabelStyle == other.appBarLabelStyle &&
        appBarIconColor == other.appBarIconColor &&
        pickerBottomBorderColor == other.pickerBottomBorderColor &&
        pickerItemLabelStyle == other.pickerItemLabelStyle &&
        pickerIconColor == other.pickerIconColor &&
        pickerListDividerColor == other.pickerListDividerColor &&
        panelBorderColor == other.panelBorderColor &&
        minimizedFabBackgroundColor == other.minimizedFabBackgroundColor &&
        minimizedFabIconColor == other.minimizedFabIconColor;
  }

  @override
  int get hashCode => Object.hashAll([
    scaffoldBackgroundColor,
    appBarBackgroundColor,
    appBarToolSelectorBackgroundColor,
    appBarToolSelectorBorderColor,
    appBarMenuUnderlineColor,
    appBarLabelStyle,
    appBarIconColor,
    pickerBottomBorderColor,
    pickerItemLabelStyle,
    pickerIconColor,
    pickerListDividerColor,
    panelBorderColor,
    minimizedFabBackgroundColor,
    minimizedFabIconColor,
  ]);
}

/// Provides [InAppDevToolsThemeData] to descendants (typically via [InAppDevTools]).
class InAppDevToolsTheme extends InheritedWidget {
  const InAppDevToolsTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final InAppDevToolsThemeData data;

  static InAppDevToolsThemeData of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InAppDevToolsTheme>();
    assert(
      scope != null,
      'InAppDevToolsTheme.of() used with no InAppDevToolsTheme ancestor; '
      'wrap with InAppDevTools or InAppDevToolsTheme.',
    );
    return scope!.data;
  }

  static InAppDevToolsThemeData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InAppDevToolsTheme>()
        ?.data;
  }

  @override
  bool updateShouldNotify(InAppDevToolsTheme oldWidget) {
    return data != oldWidget.data;
  }
}
