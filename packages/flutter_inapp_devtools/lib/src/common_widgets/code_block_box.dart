import 'package:flutter/material.dart';
import 'single_child_pan_viewport.dart';

/// Monospace code block with horizontal and vertical panning.
class CodeBlockBox extends StatelessWidget {
  const CodeBlockBox({
    required this.text,
    this.maxHeight = 116,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    super.key,
  });

  final String text;

  final double maxHeight;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        minWidth: double.infinity,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildPanViewport(
        padding: padding,
        child: Text(
          text.trim(),
          softWrap: false,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            fontFamily: 'monospace',
            color: Color(0xFFBDBDBD),
          ),
        ),
      ),
    );
  }
}
