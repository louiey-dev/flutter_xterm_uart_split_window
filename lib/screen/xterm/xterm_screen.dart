import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_xterm_uart_split_window/screen/com/com_port_screen.dart';
import 'package:xterm/xterm.dart';

late Terminal terminal;
final terminalController = TerminalController();
late final Pty pty;

class XtermScreen extends StatelessWidget {
  const XtermScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return XtermHome();
  }
}

class XtermHome extends StatefulWidget {
  const XtermHome({super.key});

  @override
  State<XtermHome> createState() => _XtermHomeState();
}

class _XtermHomeState extends State<XtermHome> {
  final FocusNode _focusNode = FocusNode();
  final bool _localEcho = true; // Toggle for local echo

  @override
  void initState() {
    super.initState();
    terminal = Terminal(maxLines: 10000);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TerminalView(
          terminal,
          controller: terminalController,
          backgroundOpacity: 0.7,
          // cursorType: TerminalCursorType.verticalBar,
          // alwaysShowCursor: true,
          // autofocus: true,
          onSecondaryTapDown: (details, offset) async {
            final selection = terminalController.selection;
            if (selection != null) {
              // 선택 영역이 있으면 복사
              final text = terminal.buffer.getText(selection);
              terminalController.clearSelection();
              await Clipboard.setData(ClipboardData(text: text));
            } else {
              // 선택 영역이 없으면 붙여넣기
              final data = await Clipboard.getData('text/plain');
              final text = data?.text;
              if (text != null) {
                terminal.paste(text);
              }
            }
          },
        ),

        // Overlay for keyboard input - this is what receives ALL events
        Positioned.fill(
          child: KeyboardListener(
            focusNode: _focusNode,
            autofocus: false,
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent) {
                _handleKey(event);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Safe - just request focus on our node
                _focusNode.requestFocus();
              },
              onSecondaryTapDown: (details) {
                _handleRightClick();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  void _handleKey(KeyEvent event) {
    final key = event.logicalKey;
    final char = event.character;

    // Special keys - use keyInput which triggers onOutput
    if (key == LogicalKeyboardKey.enter) {
      terminal.keyInput(TerminalKey.enter);
    } else if (key == LogicalKeyboardKey.backspace) {
      terminal.keyInput(TerminalKey.backspace);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      terminal.keyInput(TerminalKey.arrowUp);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      terminal.keyInput(TerminalKey.arrowDown);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      terminal.keyInput(TerminalKey.arrowLeft);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      terminal.keyInput(TerminalKey.arrowRight);
    } else if (key == LogicalKeyboardKey.tab) {
      terminal.keyInput(TerminalKey.tab);
    } else if (key == LogicalKeyboardKey.escape) {
      terminal.keyInput(TerminalKey.escape);
    } else if (key == LogicalKeyboardKey.home) {
      terminal.keyInput(TerminalKey.home);
    } else if (key == LogicalKeyboardKey.end) {
      terminal.keyInput(TerminalKey.end);
    } else if (key == LogicalKeyboardKey.pageUp) {
      terminal.keyInput(TerminalKey.pageUp);
    } else if (key == LogicalKeyboardKey.pageDown) {
      terminal.keyInput(TerminalKey.pageDown);
    } else if (key == LogicalKeyboardKey.delete) {
      terminal.keyInput(TerminalKey.delete);
    } else if (key == LogicalKeyboardKey.insert) {
      terminal.keyInput(TerminalKey.insert);
    }
    // Control sequences
    else if (HardwareKeyboard.instance.isControlPressed) {
      if (key == LogicalKeyboardKey.keyC) {
        _sendToSerial('\x03'); // Ctrl+C
      } else if (key == LogicalKeyboardKey.keyD) {
        _sendToSerial('\x04'); // Ctrl+D
      } else if (key == LogicalKeyboardKey.keyZ) {
        _sendToSerial('\x1a'); // Ctrl+Z
      } else if (key == LogicalKeyboardKey.keyL) {
        _sendToSerial('\x0c'); // Ctrl+L (clear)
      }
    }
    // Regular characters - send immediately to serial port
    else if (char != null && char.isNotEmpty) {
      _sendToSerial(char);
      // Display locally only if local echo is enabled
      if (_localEcho) {
        terminal.write(char);
      }
    }
  }

  Future<void> _handleRightClick() async {
    final selection = terminalController.selection;
    if (selection != null) {
      // Copy selected text
      final text = terminal.buffer.getText(selection);
      terminalController.clearSelection();
      await Clipboard.setData(ClipboardData(text: text));
      _showInfo('Copied');
    } else {
      // Paste from clipboard
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        terminal.paste(data!.text!);
      }
    }
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  // Helper method to send data to serial port
  void _sendToSerial(String data) {
    serialSend(data);
  }

  @override
  void dispose() {
    mSp?.close();
    super.dispose();
  }
}
