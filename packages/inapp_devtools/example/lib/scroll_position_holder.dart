import 'package:flutter/material.dart';

class ScrollPositionHolderExample extends StatefulWidget {
  const ScrollPositionHolderExample({super.key});

  @override
  State<ScrollPositionHolderExample> createState() =>
      _ScrollPositionHolderExampleState();
}

class _ScrollPositionHolderExampleState
    extends State<ScrollPositionHolderExample> {
  final List<int> _items = [];
  bool isDown = true;
  final controller = ScrollController();

  void _addItem() {
    setState(() {
      _items.add(_items.length);
    });
    _adjustScrollPosition();
  }

  void _clearItems() {
    setState(() {
      _items.clear();
    });
    _adjustScrollPosition();
  }

  void _adjustScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (isDown) {
        controller.jumpTo(controller.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scroll Position Holder Example')),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter == 0) {
                  print('Direction: isDown true');
                  isDown = true;
                } else {
                  print('Direction: isDown false');
                  isDown = false;
                }
                print('Scroll position: ${notification.metrics}');
                return false;
              },
              child: ListView.builder(
                controller: controller,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text('Item ${_items[index]}'));
                },
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addItem,
                  child: const Text('Add item'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _clearItems,
                  child: const Text('Clear items'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
