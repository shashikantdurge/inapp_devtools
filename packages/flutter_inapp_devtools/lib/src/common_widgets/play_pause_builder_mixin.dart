import 'package:flutter/material.dart';

/// Play/pause control with a badge for hidden (buffered) items while paused.
mixin PlayPauseBuilderMixin<T extends StatefulWidget> on State<T> {
  final ValueNotifier<int> _hiddenItemsCountNotifier = ValueNotifier(0);
  bool _isPaused = false;
  bool get isPaused => _isPaused;

  void setHiddenItemsCount(int count) {
    _hiddenItemsCountNotifier.value = count;
  }

  Widget buildPlayPauseButton() {
    return IconButton(
      onPressed: () {
        setState(() {
          _isPaused = !_isPaused;
        });
      },
      icon: ValueListenableBuilder(
        valueListenable: _hiddenItemsCountNotifier,
        builder: (context, value, child) {
          if (value > 0) {
            return Align(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          } else if (isPaused) {
            return Icon(Icons.play_arrow_outlined);
          } else {
            return Icon(Icons.pause_outlined);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _hiddenItemsCountNotifier.dispose();
    super.dispose();
  }
}
