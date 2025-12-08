import 'dart:async';

import 'package:convert/convert.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xterm_uart_split_window/screen/ble/responsive_view.dart';
import 'package:flutter_xterm_uart_split_window/utils.dart';
import 'package:flutter_xterm_uart_split_window/widget/my_button.dart';
import 'package:flutter_xterm_uart_split_window/widget/my_widget.dart';
import 'package:universal_ble/universal_ble.dart';

class PeripheralSelectedScreen extends StatefulWidget {
  final BleDevice bleDevice;
  final VoidCallback? onBack;
  const PeripheralSelectedScreen(this.bleDevice, {super.key, this.onBack});

  @override
  State<PeripheralSelectedScreen> createState() =>
      _PeripheralSelectedScreenState();
}

class _PeripheralSelectedScreenState extends State<PeripheralSelectedScreen> {
  bool isConnected = false;
  final List<String> _logs = [];
  List<BleService> discoveredServices = [];

  BleService? selectedService;
  BleCharacteristic? selectedCharacteristic;

  StreamSubscription? connectionStreamSubscription;
  StreamSubscription? pairingStateSubscription;

  // ? For Write value
  GlobalKey<FormState> valueFormKey = GlobalKey<FormState>();
  final binaryCode = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // ? Register the connection stream listener.
    // ? This callback will be triggered when the connection state changes.
    // ? Connect or disconnect state will be handled in this callback.
    connectionStreamSubscription = widget.bleDevice.connectionStream.listen(
      _handleConnectionChange,
    );

    // ? Register the pairing state stream listener.
    // ? This callback will be triggered when the pairing state changes.
    pairingStateSubscription = widget.bleDevice.pairingStateStream.listen(
      _handlePairingStateChange,
    );

    UniversalBle.onValueChange = _handleValueChange;

    _asyncInits();
  }

  @override
  void dispose() {
    super.dispose();
    connectionStreamSubscription?.cancel();
    pairingStateSubscription?.cancel();
    UniversalBle.onValueChange = null;
  }

  // ? This method handles connect/disconnect changes smoothly.
  // ? If this method is not here, there will happen issue when you try connect/disconnect continuously
  void _asyncInits() {
    widget.bleDevice.connectionState.then((state) {
      if (state == BleConnectionState.connected) {
        setState(() {
          isConnected = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // _displayDeviceInfo(widget.bleDevice);
    return Column(
      children: [
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
          title: Text(
            widget.bleDevice.name ?? "Unknown",
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: isConnected ? Colors.blue : Colors.red,
              ),
            ),
          ],
        ),
        Expanded(
          child: ResponsiveView(
            builder: (context, deviceType) {
              return Row(
                children: [
                  if (deviceType == DeviceType.desktop)
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: const Color.fromARGB(255, 231, 225, 248),
                        child: _displayDiscoveredServices(),
                      ),
                    ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10.0,
                        children: [
                          _showServiceInfo(),
                          Flexible(
                            child: SingleChildScrollView(
                              child: _showExtraCommand(),
                            ),
                          ),
                          Expanded(child: _logInfo()),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  _displayDiscoveredServices() {
    return discoveredServices.isEmpty
        ? const Center(child: Text('No Services Discovered'))
        : ListView.builder(
            itemCount: discoveredServices.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: ExpandablePanel(
                    header: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_forward_ios),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _findGapGattUuid(
                                  discoveredServices[index].uuid,
                                ),
                                Text(
                                  discoveredServices[index].uuid,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    collapsed: const SizedBox(),
                    expanded: Column(
                      children: discoveredServices[index].characteristics
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      myUtils.log("${e.uuid} tapped");
                                      setState(() {
                                        selectedService =
                                            discoveredServices[index];
                                        selectedCharacteristic = e;
                                      });
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.arrow_right_outlined,
                                            ),
                                            Expanded(child: Text(e.uuid)),
                                          ],
                                        ),
                                        Text(
                                          "Properties: ${e.properties.map((e) => e.name)}",
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _findGapGattUuid(String uuid) {
    List<String> id = uuid.split("-");

    if (id[0].contains('1800')) {
      return Text("GAP", style: const TextStyle(fontWeight: FontWeight.bold));
    } else if (id[0].contains('1801')) {
      return Text("GATT", style: const TextStyle(fontWeight: FontWeight.bold));
    } else {
      return Text(
        "Service",
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }
  }

  _showServiceInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              PlatformButton(
                onPressed: () async {
                  try {
                    await widget.bleDevice.connect();
                    setState(() {
                      isConnected = true;
                    });
                    _addLog(
                      "Connection",
                      "Connected to ${widget.bleDevice.name}",
                    );
                  } catch (e) {
                    _addLog("Error", "Failed to connect: $e");
                  }
                },
                text: "Connect",
                enabled: !isConnected,
              ),
              PlatformButton(
                onPressed: () {
                  if (isConnected) {
                    widget.bleDevice.disconnect();
                    setState(() {
                      isConnected = false;
                    });
                    _addLog(
                      "Disconnection",
                      "Disconnected from ${widget.bleDevice.name}",
                    );
                  } else {
                    _addLog("Info", "Already disconnected");
                  }
                },
                text: "DisConnect",
                enabled: isConnected,
              ),
            ],
          ),
          Container(
            child: selectedCharacteristic == null
                ? Text(
                    discoveredServices.isEmpty
                        ? "Please discover services"
                        : "Please select a characteristic",
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          "Characteristic: ${selectedCharacteristic!.uuid}",
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Service: ${selectedService!.uuid}"),
                            Text(
                              "Properties: ${selectedCharacteristic!.properties.map((e) => e.name).join(', ')}",
                            ),
                          ],
                        ),
                        onTap: () {
                          // utils.log("${selectedCharacteristic!.uuid} tapped");
                          // Handle characteristic tap
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  _showExtraCommand() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 247, 204, 204),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 10.0, // Horizontal space between buttons
            runSpacing: 10.0, // Vertical space between lines of buttons
            children: [
              // ? Discover services after connected
              PlatformBtnToolTip(
                tooltipStr: 'Discover services of the connected device',
                onPressed: () async {
                  _discoverServices();
                },
                enabled: isConnected,
                text: 'Discover Services',
              ),
              // ? Get the connection state
              PlatformBtnToolTip(
                tooltipStr: 'Get the connection state of the device',
                onPressed: () async {
                  _addLog(
                    'ConnectionState',
                    await widget.bleDevice.connectionState,
                  );
                },
                enabled: isConnected,
                text: 'Connection State',
              ),
              // ? Read
              PlatformBtnToolTip(
                tooltipStr: 'Read device via',
                onPressed: () {
                  _readValue();
                },
                enabled:
                    isConnected &&
                    discoveredServices.isNotEmpty &&
                    _hasSelectedCharacteristicProperty([
                      CharacteristicProperty.read,
                    ]),
                text: 'Read',
              ),
              // ? Write
              PlatformBtnToolTip(
                tooltipStr: 'Write value to device',
                onPressed: () async {
                  _writeMenu(true);
                },
                enabled:
                    isConnected &&
                    discoveredServices.isNotEmpty &&
                    _hasSelectedCharacteristicProperty([
                      CharacteristicProperty.write,
                    ]),
                text: 'Write',
              ),
              // ? Write w/o response
              PlatformBtnToolTip(
                tooltipStr: 'Write without response',
                onPressed: () async {
                  _writeMenu(false);
                },
                enabled:
                    isConnected &&
                    discoveredServices.isNotEmpty &&
                    _hasSelectedCharacteristicProperty([
                      CharacteristicProperty.writeWithoutResponse,
                    ]),
                text: 'WriteWithoutResponse',
              ),
            ],
          ),
          myHEIGHT(10),
          // ? Extra commands buttons
          Wrap(
            spacing: 10.0, // Horizontal space between buttons
            runSpacing: 10.0, // Vertical space between lines of buttons
            children: [
              // ? Request MTU
              PlatformBtnToolTip(
                tooltipStr: 'Request MTU value',
                onPressed: () async {
                  int mtu = await widget.bleDevice.requestMtu(247);
                  _addLog('MTU', mtu);
                },
                enabled: isConnected,
                text: 'Request MTU',
              ),
              // ? Subscribe
              PlatformBtnToolTip(
                tooltipStr: 'Subscribe to characteristic notifications',
                onPressed: () {
                  _subscribeChar();
                },
                enabled:
                    isConnected &&
                    discoveredServices.isNotEmpty &&
                    _hasSelectedCharacteristicProperty([
                      CharacteristicProperty.notify,
                      CharacteristicProperty.indicate,
                    ]),
                text: 'Subscribe',
              ),
              // ? Unsubscribe
              PlatformBtnToolTip(
                tooltipStr: 'Unsubscribe from characteristic notifications',
                onPressed: () {
                  _unsubscribeChar();
                },
                enabled:
                    isConnected &&
                    discoveredServices.isNotEmpty &&
                    _hasSelectedCharacteristicProperty([
                      CharacteristicProperty.notify,
                      CharacteristicProperty.indicate,
                    ]),
                text: 'Unsubscribe',
              ),
              // ? Pairing
              PlatformBtnToolTip(
                tooltipStr: 'Pairing with connected device',
                onPressed: () async {
                  try {
                    await widget.bleDevice.pair();
                    _addLog("Pairing Result", true);
                  } catch (e) {
                    _addLog('PairError (${e.runtimeType})', e);
                  }
                },
                enabled: BleCapabilities.supportsAllPairingKinds,
                text: 'Pair',
              ),
              // ? Check paired status
              PlatformBtnToolTip(
                tooltipStr: 'Check whether devise is paired',
                onPressed: () async {
                  bool? isPaired = await widget.bleDevice.isPaired();
                  _addLog('isPaired', isPaired);
                },
                enabled: isConnected,
                text: 'isPaired',
              ),
              // ? UnPairing
              PlatformBtnToolTip(
                tooltipStr: 'UnPair the device',
                onPressed: () async {
                  await widget.bleDevice.unpair();
                },
                enabled: isConnected,
                text: 'UnPair',
              ),
            ],
          ),
        ],
      ),
    );
  }

  _logInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 183, 241, 149),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                const Text(
                  "Log Info",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                myWIDTH(20),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  icon: Icon(Icons.cleaning_services_outlined),
                ),
              ],
            ),
          ),
          myHEIGHT(10),
          Expanded(
            child: Container(
              width: double.infinity,
              // height: 400, // Let Expanded handle the height
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, idx) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _logs[idx],
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return Divider(thickness: 2);
                  },
                  itemCount: _logs.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _writeMenu(bool withResponse) {
    final writeValue = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: withResponse
              ? Text('Write Value With Response')
              : Text("Write Value Without Response"),
          content: Text('write input value (00, 01, ...)'),
          actions: [
            TextField(
              controller: writeValue,
              decoration: InputDecoration(
                labelText: 'Hex Value',
                hintText: 'Enter hex value to write without 0x',
              ),
              keyboardType: TextInputType.text,
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                _addLog("Cancel pressed", true);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Write'),
              onPressed: () {
                _addLog("Write pressed", true);
                _writeValueFromPopup(
                  writeValue.text,
                  withResponse: withResponse,
                );
                // 삭제 작업 수행
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _displayDeviceInfo(BleDevice device) {
    myUtils.log("${getCurrentMethodName()} : Displaying device info");
    myUtils.log("name : ${device.name}");
    myUtils.log("id : ${device.deviceId}");
    myUtils.log("rssi : ${device.rssi.toString()}");
    myUtils.log("rawName : ${device.rawName}");
    myUtils.log("rssi : ${device.rssi}");
    for (int i = 0; i < device.services.length; i++) {
      myUtils.log("service[$i] : ${device.services[i]}");
    }
    // utils.log("services : ${device.services}");
  }

  Future<void> _discoverServices() async {
    const webWarning =
        "Note: Only services added in ScanFilter or WebOptions will be discovered";
    try {
      var services = await widget.bleDevice.discoverServices();
      _addLog(
        '${getCurrentMethodName()} : ${services.length} services discovered',
        true,
      );
      _addLog("${getCurrentMethodName()} : ${services.toString()}\n", true);
      setState(() {
        discoveredServices = services;
      });

      if (kIsWeb) {
        _addLog(
          "DiscoverServices",
          '${services.length} services discovered,\n$webWarning',
        );
      }
    } catch (e) {
      _addLog("DiscoverServicesError", '$e\n${kIsWeb ? webWarning : ""}');
    }
  }

  Future<void> _subscribeChar() async {
    BleCharacteristic? selectedCharacteristic = this.selectedCharacteristic;
    if (selectedCharacteristic == null) return;
    try {
      var subscription = _getCharacteristicSubscription(selectedCharacteristic);
      if (subscription == null) throw 'No notify or indicate property';
      await subscription.subscribe();
      _addLog('BleCharSubscription', 'Subscribed');
      // Updates can also be handled by
      // subscription.listen((data) {});
    } catch (e) {
      _addLog('NotifyError', e);
      myUtils.log(e.toString());
    }
  }

  Future<void> _unsubscribeChar() async {
    try {
      await selectedCharacteristic?.unsubscribe();
      _addLog('BleCharSubscription', 'UnSubscribed');
    } catch (e) {
      myUtils.e(e.toString());
      _addLog('NotifyError', e);
    }
  }

  CharacteristicSubscription? _getCharacteristicSubscription(
    BleCharacteristic characteristic,
  ) {
    var properties = characteristic.properties;
    if (properties.contains(CharacteristicProperty.notify)) {
      return characteristic.notifications;
    } else if (properties.contains(CharacteristicProperty.indicate)) {
      return characteristic.indications;
    }
    return null;
  }

  bool _hasSelectedCharacteristicProperty(
    List<CharacteristicProperty> properties,
  ) {
    return properties.any(
      (property) =>
          selectedCharacteristic?.properties.contains(property) ?? false,
    );
  }

  Future<void> _readValue() async {
    BleCharacteristic? selectedCharacteristic = this.selectedCharacteristic;
    if (selectedCharacteristic == null) return;
    try {
      Uint8List value = await selectedCharacteristic.read();
      String s = String.fromCharCodes(value);
      String data = '$s\nraw :  ${value.toString()}';
      _addLog('Read', data);
    } catch (e) {
      _addLog('ReadError', e);
    }
  }

  Future<void> _writeValue({required bool withResponse}) async {
    BleCharacteristic? selectedCharacteristic = this.selectedCharacteristic;
    if (selectedCharacteristic == null ||
        !valueFormKey.currentState!.validate() ||
        binaryCode.text.isEmpty) {
      return;
    }

    Uint8List value;
    try {
      value = Uint8List.fromList(hex.decode(binaryCode.text));
    } catch (e) {
      _addLog('WriteError', "Error parsing hex $e");
      myUtils.e("${userFunc()} : $e");
      return;
    }

    try {
      await selectedCharacteristic.write(value, withResponse: withResponse);
      _addLog('Write${withResponse ? "" : "WithoutResponse"}', value);
    } catch (e) {
      debugPrint(e.toString());
      _addLog('WriteError', e);
    }
  }

  Future<void> _writeValueFromPopup(
    String binCode, {
    required bool withResponse,
  }) async {
    BleCharacteristic? selectedCharacteristic = this.selectedCharacteristic;
    if (selectedCharacteristic == null ||
        // !valueFormKey.currentState!.validate() ||
        binCode.isEmpty) {
      return;
    }

    Uint8List value;
    try {
      value = Uint8List.fromList(hex.decode(binCode));
      _addLog("Write value $value", true);
    } catch (e) {
      _addLog('WriteError', "Error parsing hex $e");
      myUtils.e("${userFunc()} : $e");
      return;
    }

    try {
      _addLog('Write${withResponse ? "" : "WithoutResponse"}', value);
      await selectedCharacteristic.write(value, withResponse: withResponse);
    } catch (e) {
      debugPrint(e.toString());
      _addLog('WriteError', e);
    }
  }

  // callback when device is connected
  // need to register at bleDevice.connectionStream.listen
  void _handleConnectionChange(bool isConnected) {
    myUtils.log('_handleConnectionChange $isConnected');
    setState(() {
      this.isConnected = isConnected;
    });
    _addLog('Connection', isConnected ? "Connected" : "Disconnected");
    // Auto Discover Services
    if (this.isConnected) {
      // utils.log("Start to discover services");
      _discoverServices();
    }
  }

  // ? Pairing state change callback
  void _handlePairingStateChange(bool isPaired) {
    debugPrint('isPaired $isPaired');
    _addLog("PairingStateChange - isPaired", isPaired);
  }

  void _handleValueChange(
    String deviceId,
    String characteristicId,
    Uint8List value,
  ) {
    String s = String.fromCharCodes(value);
    String data = '$s\nraw :  ${value.toString()}';
    debugPrint('_handleValueChange $characteristicId, $s');
    _addLog("Value", data);
  }

  void _addLog(String type, dynamic data) {
    setState(() {
      _logs.add('$type: ${data.toString()}');
    });
    // Scroll to the bottom after adding new content
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }
}
