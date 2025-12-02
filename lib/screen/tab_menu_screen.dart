import 'package:flutter/material.dart';
import 'package:flutter_xterm_uart_split_window/screen/com_port_screen.dart';
import 'package:getwidget/components/tabs/gf_tabbar_view.dart';
import 'package:getwidget/components/tabs/gf_tabs.dart';

class TabMenuScreen extends StatefulWidget {
  const TabMenuScreen({super.key});

  @override
  State<TabMenuScreen> createState() => _TabMenuScreenState();
}

class _TabMenuScreenState extends State<TabMenuScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GFTabs(
      controller: tabController,
      length: 3,
      tabBarHeight: 30,
      tabs: <Widget>[
        Tab(icon: Icon(Icons.link)),
        Tab(icon: Icon(Icons.directions_bus)),
        Tab(icon: Icon(Icons.directions_railway)),
      ],
      tabBarView: GFTabBarView(
        controller: tabController,
        children: <Widget>[
          ComScreen(),
          Container(color: Colors.blue, child: Icon(Icons.directions_bus)),
          Container(
            color: Colors.orange,
            child: Icon(Icons.directions_railway),
          ),
        ],
      ),
    );
  }
}
