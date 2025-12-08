import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xterm_uart_split_window/screen/ble/peripheral_select_screen.dart';
import 'package:flutter_xterm_uart_split_window/screen/ble/scan_menu_widget.dart';
import 'package:flutter_xterm_uart_split_window/screen/ble/scanned_item_widget.dart';
import 'package:flutter_xterm_uart_split_window/utils.dart';
import 'package:flutter_xterm_uart_split_window/widget/my_widget.dart';
import 'package:universal_ble/universal_ble.dart';

final ScrollController scanScrollController = ScrollController();
List<String> scanMessage = [];
final TextEditingController advNameController = TextEditingController();

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  bool _isScanning = false;
  final _bleDevices = <BleDevice>[];
  bool _isNaChecked = true;
  BleDevice? _selectedDevice;

  AvailabilityState? bleAvailabilityState;

  @override
  void initState() {
    super.initState();
    _bleDevices.clear();

    /// Setup queue and timeout
    UniversalBle.queueType = QueueType.global;
    UniversalBle.timeout = const Duration(seconds: 10);

    UniversalBle.availabilityStream.listen((state) {
      setState(() {
        bleAvailabilityState = state;
      });
    });

    UniversalBle.scanStream.listen((result) {
      if (_isNaChecked) {
        if (result.name == null || result.name!.isEmpty) {
          myUtils.log(
            "Device name is null or empty, skipping: ${result.deviceId}",
          );
          return;
        }
      }

      int index = _bleDevices.indexWhere((e) => e.deviceId == result.deviceId);
      if (index == -1) {
        _bleDevices.add(result);
      } else {
        if (result.name == null && _bleDevices[index].name != null) {
          result.name = _bleDevices[index].name;
        }
        _bleDevices[index] = result;
      }

      _addScanMessage(result.name, result.deviceId);

      myUtils.log("name : ${result.name}");
      setState(() {});
    });
  }

  _addScanMessage(String? name, String id) {
    if (name == null || name.isEmpty) {
      // skip
    } else if (scanMessage.any(
      (element) => element.contains(name) || element.contains(id),
    )) {
      // skip
      myUtils.log("Device already exists in scanMessage: $name");
    } else {
      scanMessage.add("Device found: $name - $id");
      // Scroll to the bottom after adding a new message
      // scanScrollController.jumpTo(
      //   scanScrollController.position.maxScrollExtent,
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDevice != null) {
      return PeripheralSelectedScreen(
        _selectedDevice!,
        onBack: () => setState(() => _selectedDevice = null),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            ScanMenuWidget(
              isScanning: _isScanning,
              onScanPressed: _startScan,
              onStopPressed: _stopScan,
              // onNaPressed: _filterNA,
            ),
            CupertinoSwitch(
              value: _isNaChecked,
              onChanged: (value) {
                setState(() {
                  _isNaChecked = value;
                });
                myUtils.log("Switched to : $_isNaChecked");
                myUtils.showSnackbar(context, "Switched to: $_isNaChecked");
              },
            ),
            myWIDTH(5),
            const Text("N/A"),
          ],
        ),
        myWIDTH(30),
        SizedBox(
          width: 200,
          child: TextField(
            controller: advNameController,
            decoration: const InputDecoration(
              labelText: 'Filter by Advertised Name',
              hintText: 'e.g. ble, spp...',
            ),
          ),
        ),
        // Show scan results
        _showScanResults(),
        myHEIGHT(10),
      ],
    );
  }

  Future<void> startScan() async {
    await UniversalBle.startScan();
  }

  void _startScan() async {
    setState(() {
      scanMessage.clear();
      _bleDevices.clear();
      _isScanning = true;
    });
    myUtils.log("Starting scan for BLE devices...");

    try {
      await startScan();
    } catch (e) {
      if (!mounted) return;
      myUtils.showSnackbar(context, e.toString());
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _stopScan() async {
    await UniversalBle.stopScan();

    setState(() {
      _isScanning = false;
      myUtils.log("Stopping scan for BLE devices...");
    });
  }

  Widget _showScanResults() {
    return Expanded(
      child: _isScanning && _bleDevices.isEmpty
          ? const Center(child: CircularProgressIndicator.adaptive())
          : !_isScanning && _bleDevices.isEmpty
          ? const Text("Scan for devices")
          : ListView.separated(
              itemCount: _bleDevices.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                BleDevice device = _bleDevices[_bleDevices.length - index - 1];

                return ScannedItemWidget(
                  bleDevice: device,
                  onTap: () {
                    myUtils.log(
                      "Tapped on device: ${device.name} (${device.deviceId})",
                    );
                    setState(() => _selectedDevice = device);
                  },
                );
              },
            ),
    );
  }
}
