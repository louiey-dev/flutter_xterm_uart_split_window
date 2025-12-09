import 'package:flutter/material.dart';

class BleMenu extends StatefulWidget {
  const BleMenu({super.key});

  @override
  State<BleMenu> createState() => _BleMenuState();
}

class _BleMenuState extends State<BleMenu> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("BLE Menu"));
  }
}
