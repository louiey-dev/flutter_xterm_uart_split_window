import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformButton extends StatelessWidget {
  final String text;
  final void Function()? onPressed;
  final bool enabled;

  // final double width = 100;
  // final double height = 30;

  const PlatformButton({
    required this.text,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return (!kIsWeb && (Platform.isMacOS || Platform.isIOS))
        ? CupertinoButton.filled(
          onPressed: enabled ? onPressed : null,
          // color: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          disabledColor: Colors.grey,
          child: Text(text),
        )
        : ElevatedButton(
          style: ElevatedButton.styleFrom(
            // minimumSize: Size(width, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          onPressed: enabled ? onPressed : null,
          child: Text(text),
        );
  }
}

// @param tooltipStr: The tooltip string to display when hovering over the button.
// @param duration: The duration in seconds for which the tooltip will be displayed.
// @param text: The text to display on the button.
// @param onPressed: The callback function to execute when the button is pressed.
// @param enabled: A boolean indicating whether the button is enabled or not.
class PlatformBtnToolTip extends StatelessWidget {
  final String tooltipStr;
  final int duration;

  final String text;
  final void Function()? onPressed;
  final bool enabled;

  const PlatformBtnToolTip({
    required this.tooltipStr,
    this.duration = 1,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipStr,
      waitDuration: Duration(seconds: duration),
      child: PlatformButton(onPressed: onPressed, text: text, enabled: enabled),
    );
  }
}
