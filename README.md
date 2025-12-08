# flutter_xterm_uart_split_window

Split window with xterm terminal view which can connect to uart.</br>
User can add what you want to middle/right screen or increase more windows.

![main screen](screen.png)

## Getting Started

xterm window + user window + chart window and so on</br>
multi_split_view + xterm + flutter_libserial + pty

## TODO

- pty running on xterm
  - it was work before without an issue but there happenning key input related errors so currently, pty feature disabled.
- BLE screen at middle window

## History

- 2025.12.02
  - Basic feature is working
- 2025.12.08
  - BLE screen added
    - Scan/Connect/Subscribe/Read/Write works
  - several overflow error fixed

## Info

- Author : Louie Yang
- Flutter 3.35.7 • channel stable • <https://github.com/flutter/flutter.git></br>
Framework • revision adc9010625 (6 weeks ago) • 2025-10-21 14:16:03 -0400</br>
Engine • hash 6b24e1b529bc46df7ff397667502719a2a8b6b72 (revision 035316565a) (1 months ago) • 2025-10-21 14:28:01.000Z</br>
Tools • Dart 3.9.2 • DevTools 2.48.0
