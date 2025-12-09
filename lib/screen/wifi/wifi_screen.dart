import 'package:flutter/material.dart';

class WiFiScreen extends StatefulWidget {
  const WiFiScreen({super.key});

  @override
  State<WiFiScreen> createState() => _WiFiScreenState();
}

class _WiFiScreenState extends State<WiFiScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages =
      []; // Changed to Map for more info
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  final List<String> _commandHistory = []; // Command history
  int _historyIndex = -1; // Current position in history
  String _currentInput = ''; // Save current input when browsing history

  final bool _autoScroll = true; // Auto-scroll to bottom

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(children: [_buildMessagesArea()]),
    );
  }

  Widget _buildMessagesArea() {
    return Expanded(
      child: Container(
        color: Colors.black,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final msgData = _messages[index];
            final isReceived = msgData['type'] == 'rx';
            final message = msgData['data'] as String;
            final time = msgData['time'] as DateTime;
            final timeStr =
                '${time.hour.toString().padLeft(2, '0')}:'
                '${time.minute.toString().padLeft(2, '0')}:'
                '${time.second.toString().padLeft(2, '0')}.'
                '${time.millisecond.toString().padLeft(3, '0')}';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Direction indicator
                  Container(
                    width: 28,
                    alignment: Alignment.center,
                    child: Text(
                      isReceived ? '◄◄' : '►►',
                      style: TextStyle(
                        color: isReceived ? Colors.green : Colors.cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Timestamp
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isReceived
                          ? Colors.green.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      isReceived ? 'RX' : 'TX',
                      style: TextStyle(
                        color: isReceived ? Colors.green : Colors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Message content
                  Expanded(
                    child: SelectableText(
                      message,
                      style: TextStyle(
                        color: isReceived
                            ? Colors.green[300]
                            : Colors.cyan[300],
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: isReceived
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add to command history (avoid duplicates of last command)
    if (_commandHistory.isEmpty || _commandHistory.last != message) {
      _commandHistory.add(message);
      // Limit history to 50 commands
      if (_commandHistory.length > 50) {
        _commandHistory.removeAt(0);
      }
    }

    // Reset history index
    _historyIndex = -1;
    _currentInput = '';

    // _tcpClient.sendLine(message);

    setState(() {
      _messages.add({'type': 'tx', 'data': message, 'time': DateTime.now()});
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
}
