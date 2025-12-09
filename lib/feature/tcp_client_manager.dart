// ==============================================================
// TCP Client Manager Class
// ==============================================================
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_xterm_uart_split_window/utils.dart';

class TCPClientManager {
  Socket? _socket;
  StreamSubscription? _subscription;

  final StreamController<String> _dataController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<String> get dataStream => _dataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _socket != null;

  // Connect to TCP server
  Future<bool> connect(String host, int port, {Duration? timeout}) async {
    try {
      // Close existing connection if any
      await disconnect();

      // Connect with timeout
      _socket = await Socket.connect(
        host,
        port,
        timeout: timeout ?? const Duration(seconds: 5),
      );

      myUtils.log('✅ Connected to $host:$port');
      _connectionController.add(true);

      // Listen to incoming data
      _subscription = _socket!.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      return true;
    } catch (e) {
      myUtils.log('❌ Connection failed: $e');
      _connectionController.add(false);
      return false;
    }
  }

  // Disconnect from server
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    _socket?.destroy();
    _socket = null;

    _connectionController.add(false);
    myUtils.log('🔌 Disconnected');
  }

  // Send string data
  void sendString(String data) {
    if (_socket == null) {
      myUtils.log('❌ Cannot send: Not connected');
      return;
    }

    try {
      _socket!.write(data);
      myUtils.log('📤 Sent: $data');
    } catch (e) {
      myUtils.log('❌ Send error: $e');
    }
  }

  // Send bytes
  void sendBytes(Uint8List data) {
    if (_socket == null) {
      myUtils.log('❌ Cannot send: Not connected');
      return;
    }

    try {
      _socket!.add(data);
      myUtils.log('📤 Sent ${data.length} bytes');
    } catch (e) {
      myUtils.log('❌ Send error: $e');
    }
  }

  // Send with newline terminator
  void sendLine(String data) {
    sendString('$data\n');
  }

  // Data received callback
  void _onData(Uint8List data) {
    final text = String.fromCharCodes(data);
    myUtils.log('📥 Received: $text');
    _dataController.add(text);
  }

  // Error callback
  void _onError(error) {
    myUtils.log('❌ Socket error: $error');
    _connectionController.add(false);
  }

  // Connection closed callback
  void _onDone() {
    myUtils.log('⚠️ Server closed connection');
    _connectionController.add(false);
    disconnect();
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _dataController.close();
    _connectionController.close();
  }
}
