import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xterm_uart_split_window/screen/ble/ble_scan.dart';
import 'package:flutter_xterm_uart_split_window/screen/tab_menu_screen.dart';
import 'package:flutter_xterm_uart_split_window/screen/xterm/xterm_screen.dart';
import 'package:multi_split_view/multi_split_view.dart';

class MultiSplitViewScreen extends StatefulWidget {
  const MultiSplitViewScreen({super.key});

  @override
  State<MultiSplitViewScreen> createState() => _MultiSplitViewScreenState();
}

class _MultiSplitViewScreenState extends State<MultiSplitViewScreen> {
  late final MultiSplitViewController _multiViewcontroller;
  late final Widget _xtermScreen;

  @override
  void initState() {
    super.initState();
    _xtermScreen = XtermScreen();

    _multiViewcontroller = MultiSplitViewController(
      areas: [
        Area(
          flex: 3,
          builder: (context, area) => MultiSplitView(
            // onDividerDragUpdate: _onDividerDragUpdate,
            // onDividerTap: _onDividerTap,
            // onDividerDoubleTap: _onDividerDoubleTap,
            initialAreas: [
              Area(
                builder: (context, area) => Container(
                  color: Colors.lightBlueAccent,
                  child: _xtermScreen,
                ),
              ),
              Area(
                builder: (context, area) =>
                    Container(color: Colors.yellow, child: BleScanScreen()),
              ),
              Area(
                builder: (context, area) =>
                    Container(color: Colors.green, child: Text("Right")),
              ),
            ],
          ),
        ),
        Area(
          // flex: 1,
          size: 140.0,
          builder: (context, area) =>
              Container(color: Colors.orange, child: TabMenuScreen()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi Split View Example')),
      body: Column(
        children: [
          Expanded(
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                dividerPainter: DividerPainters.grooved2(
                  color: Colors.grey[400]!,
                  highlightedColor: Colors.red,
                ),
              ),
              child: MultiSplitView(
                axis: Axis.vertical,
                controller: _multiViewcontroller,
              ),
            ),
          ),
        ],
      ),
      // body: horizontal,
    );
  }

  _onDividerDragUpdate(int index) {
    if (kDebugMode) {
      print('drag update: $index');
    }
  }

  _onDividerDoubleTap(int dividerIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text("Double tap on divider: $dividerIndex"),
      ),
    );
  }

  _onDividerTap(int dividerIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text("Tap on divider: $dividerIndex"),
      ),
    );
  }
}
