import 'package:flutter/material.dart';

/// Theme extension for JSON tree colors inspired by Postman
class PrettyJsonTheme extends ThemeExtension<PrettyJsonTheme> {
  const PrettyJsonTheme({
    required this.keyColor,
    required this.listIndexColor,
    required this.stringColor,
    required this.numberColor,
    required this.booleanColor,
    required this.nullColor,
    required this.bracketColor,
    required this.colonColor,
    required this.commentColor,
    required this.expandIconColor,
    required this.expandIconBorderColor,
    required this.lineNumberTextColor,
    required this.lineNumberBackgroundColor,
    required this.dropdownIconColor,
    required this.specialCharColor,
    required this.collapsedValueTextColor,
    required this.collapsedValueBackgroundColor,
  });

  final Color keyColor;
  final Color stringColor;
  final Color numberColor;
  final Color booleanColor;
  final Color nullColor;
  final Color bracketColor;
  final Color colonColor;
  final Color commentColor;
  final Color expandIconColor;
  final Color expandIconBorderColor;
  final Color listIndexColor;
  final Color lineNumberTextColor;
  final Color lineNumberBackgroundColor;
  final Color dropdownIconColor;
  final Color specialCharColor;
  final Color collapsedValueTextColor;
  final Color collapsedValueBackgroundColor;

  /// Light theme colors (Postman-inspired)
  factory PrettyJsonTheme.light() => const PrettyJsonTheme(
    keyColor: Color(0xFF0B5394), // Dark blue for keys
    stringColor: Color(0xFF37865D), // Green for strings
    numberColor: Color(0xFF1E5AAE), // Blue for numbers
    booleanColor: Color(0xFFCC6E03), // Orange for booleans
    nullColor: Color(0xFFA91E2C), // Red for null
    bracketColor: Color(0xFF5F6368), // Gray for brackets
    colonColor: Color(0xFF5F6368), // Gray for colons
    commentColor: Color(0xFF999999), // Light gray for comments
    expandIconColor: Color(0xFF0B5394), // Blue for icons
    expandIconBorderColor: Color(0xFFB3D4FF), // Light blue border
    listIndexColor: Color(0x800B5394), // Blue for list indices at 50% opacity
    lineNumberTextColor: Color(0xFF5F6368), // Gray for line numbers
    lineNumberBackgroundColor: Color(0xFFF5F5F5), // Light gray background
    dropdownIconColor: Color(0xFF5F6368), // Gray for dropdown icon
    specialCharColor: Color(0xFF1E5AAE), // Blue for escape sequences
    collapsedValueTextColor: Color(0xFF5F6368), // Gray for collapsed preview
    collapsedValueBackgroundColor: Color(
      0x335F6368,
    ), // Gray at 20% for collapsed background
  );

  /// Dark theme colors (Postman-inspired)
  factory PrettyJsonTheme.dark() => const PrettyJsonTheme(
    keyColor: Color(0xFF8AB4F8), // Light blue for keys
    stringColor: Color(0xFF81C995), // Light green for strings
    numberColor: Color(0xFF6BA4F7), // Light blue for numbers
    booleanColor: Color(0xFFFAB87F), // Light orange for booleans
    nullColor: Color(0xFFF28B82), // Light red for null
    bracketColor: Color(0xFFBDC1C6), // Light gray for brackets
    colonColor: Color(0xFFBDC1C6), // Light gray for colons
    commentColor: Color(0xFF9AA0A6), // Gray for comments
    expandIconColor: Color(0xFF8AB4F8), // Light blue for icons
    expandIconBorderColor: Color(0xFF4A5568), // Dark gray border
    listIndexColor: Color(
      0x808AB4F8,
    ), // Light blue for list indices at 50% opacity
    lineNumberTextColor: Color(0xFF9AA0A6), // Light gray for line numbers
    lineNumberBackgroundColor: Color(0xFF2D3748), // Dark gray background
    dropdownIconColor: Color(0xFF8AB4F8), // Light blue for dropdown icon
    specialCharColor: Color(0xFF6BA4F7), // Light blue for escape sequences
    collapsedValueTextColor: Color(
      0xFF9AA0A6,
    ), // Light gray for collapsed preview
    collapsedValueBackgroundColor: Color(
      0x33BDC1C6,
    ), // Light gray at 20% for collapsed background
  );

  @override
  PrettyJsonTheme copyWith({
    Color? keyColor,
    Color? stringColor,
    Color? numberColor,
    Color? booleanColor,
    Color? nullColor,
    Color? bracketColor,
    Color? colonColor,
    Color? commentColor,
    Color? expandIconColor,
    Color? expandIconBorderColor,
    Color? listIndexColor,
    Color? lineNumberTextColor,
    Color? lineNumberBackgroundColor,
    Color? dropdownIconColor,
    Color? specialCharColor,
    Color? collapsedValueTextColor,
    Color? collapsedValueBackgroundColor,
  }) {
    return PrettyJsonTheme(
      keyColor: keyColor ?? this.keyColor,
      stringColor: stringColor ?? this.stringColor,
      numberColor: numberColor ?? this.numberColor,
      booleanColor: booleanColor ?? this.booleanColor,
      nullColor: nullColor ?? this.nullColor,
      bracketColor: bracketColor ?? this.bracketColor,
      colonColor: colonColor ?? this.colonColor,
      commentColor: commentColor ?? this.commentColor,
      expandIconColor: expandIconColor ?? this.expandIconColor,
      expandIconBorderColor:
          expandIconBorderColor ?? this.expandIconBorderColor,
      listIndexColor: listIndexColor ?? this.listIndexColor,
      lineNumberTextColor: lineNumberTextColor ?? this.lineNumberTextColor,
      lineNumberBackgroundColor:
          lineNumberBackgroundColor ?? this.lineNumberBackgroundColor,
      dropdownIconColor: dropdownIconColor ?? this.dropdownIconColor,
      specialCharColor: specialCharColor ?? this.specialCharColor,
      collapsedValueTextColor:
          collapsedValueTextColor ?? this.collapsedValueTextColor,
      collapsedValueBackgroundColor:
          collapsedValueBackgroundColor ?? this.collapsedValueBackgroundColor,
    );
  }

  @override
  PrettyJsonTheme lerp(ThemeExtension<PrettyJsonTheme>? other, double t) {
    if (other is! PrettyJsonTheme) return this;
    return PrettyJsonTheme(
      keyColor: Color.lerp(keyColor, other.keyColor, t)!,
      stringColor: Color.lerp(stringColor, other.stringColor, t)!,
      numberColor: Color.lerp(numberColor, other.numberColor, t)!,
      booleanColor: Color.lerp(booleanColor, other.booleanColor, t)!,
      nullColor: Color.lerp(nullColor, other.nullColor, t)!,
      bracketColor: Color.lerp(bracketColor, other.bracketColor, t)!,
      colonColor: Color.lerp(colonColor, other.colonColor, t)!,
      commentColor: Color.lerp(commentColor, other.commentColor, t)!,
      expandIconColor: Color.lerp(expandIconColor, other.expandIconColor, t)!,
      expandIconBorderColor: Color.lerp(
        expandIconBorderColor,
        other.expandIconBorderColor,
        t,
      )!,
      listIndexColor: Color.lerp(listIndexColor, other.listIndexColor, t)!,
      lineNumberTextColor: Color.lerp(
        lineNumberTextColor,
        other.lineNumberTextColor,
        t,
      )!,
      lineNumberBackgroundColor: Color.lerp(
        lineNumberBackgroundColor,
        other.lineNumberBackgroundColor,
        t,
      )!,
      dropdownIconColor: Color.lerp(
        dropdownIconColor,
        other.dropdownIconColor,
        t,
      )!,
      specialCharColor: Color.lerp(
        specialCharColor,
        other.specialCharColor,
        t,
      )!,
      collapsedValueTextColor: Color.lerp(
        collapsedValueTextColor,
        other.collapsedValueTextColor,
        t,
      )!,
      collapsedValueBackgroundColor: Color.lerp(
        collapsedValueBackgroundColor,
        other.collapsedValueBackgroundColor,
        t,
      )!,
    );
  }
}
