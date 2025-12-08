import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

MyUtils myUtils = MyUtils(Level.all);

class MyUtils {
  var logger = Logger(
    filter: null, // Use the default LogFilter (-> only log in debug mode)
    printer: PrettyPrinter(), // Use the PrettyPrinter to format and print log
    output: null, // Use the default LogOutput (-> send everything to console)
  );

  late File logFile;
  String logBuffer = '';

  MyUtils(Level lvl) {
    Logger.level = lvl;

    // _logFileInit();
  }

  // log file handler
  int logFileMaxSize = 1000;
  Future<void> logFileOpen() async {
    try {
      // if (logFile == null) {
      //   logger.e("log file is null");
      //   return;
      // }

      final directory = await getApplicationDocumentsDirectory();
      String formatDate = DateFormat(
        'yyyy_MM_dd-HH_mm_ss',
      ).format(DateTime.now());
      logFile = File('${directory.path}\\$formatDate.log');
      if (!await logFile.exists()) {
        await logFile.create();
        log("log file created\n");
      }
    } catch (ex) {
      logger.e(ex);
      return;
    }
  }

  Future<void> logFileClose() async {
    try {
      _logSave();
      if (await logFile.exists()) {
        // await logFile.delete();
        log("log file closed\n");
      }
    } catch (ex) {
      logger.e(ex);
      return;
    }
  }

  void logFileWrite(String text) {
    logBuffer += text;
    if (logBuffer.length > logFileMaxSize) {
      // 버퍼가 일정 크기 이상이면 파일에 저장
      _logSave();
    }
  }

  Future<void> logFileWriteString(String text) async {
    await logFile.writeAsString(text, mode: FileMode.append, flush: true);
    // await logFile.writeAsString(text);
  }

  Future<void> _logSave() async {
    if (logBuffer.isNotEmpty) {
      await logFile.writeAsString(logBuffer, mode: FileMode.append);
      logBuffer = '';
    }
  }
  ///////////////////////////////////////////////////////

  void showSnackbar(BuildContext context, String msg) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 1),
      content: Text(msg),
      backgroundColor: Colors.blue,
      action: SnackBarAction(
        label: "Done",
        textColor: Colors.black,
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showSnackbarError(BuildContext context, String msg) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(msg),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: "Done",
        textColor: Colors.red[400],
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void log(String msg) {
    if (kDebugMode) {
      debugPrint(msg);
    }
  }

  String listIntToString(List<int> list) {
    return utf8.decode(list);
  }

  List<Uint8List> stringToUint8ListList(String str) {
    List<int> list = utf8.encode(str);
    return List.from(list);
  }

  Uint8List stringToUint8List(String str) {
    final List<int> codeUnits = str.codeUnits;
    final Uint8List unit8List = Uint8List.fromList(codeUnits);

    return unit8List;
  }

  String uint8ListToString(Uint8List uint8list) {
    return String.fromCharCodes(uint8list);
  }

  String removeNullFromString(String str) {
    return str.replaceAll(RegExp('\\0'), '');
  }

  List<int> stringToListInt(String str) {
    List<int> list = utf8.encode(str);
    return list;
  }
  // String getStrFromListInt(List<int> buf, int start, int len) {
  //   String str = String.fromCharCodes(buf, start);

  //   for (String e in buf) {
  //     str += e.toString();
  //   }
  // }

  Divider divider({
    double thickness = 2.0,
    double height = 30.0,
    double indent = 10.0,
    double endIndent = 20.0,
    Color color = Colors.green,
  }) {
    // final thickness0 = thickness;
    // final height;
    // final indent;
    // final endIndent;
    // final color;

    return Divider(
      thickness: thickness,
      color: color,
      height: height,
      indent: indent,
      endIndent: endIndent,
    );
  }

  d(String str) {
    logger.d(str);
  }

  t(String str) {
    logger.t(str);
  }

  i(String str) {
    logger.i(str);
  }

  w(String str) {
    logger.w(str);
  }

  err(String str, String errMsg) {
    logger.e(str, time: DateTime.now(), error: errMsg);
  }

  e(String str) {
    logger.e(str, time: DateTime.now());
  }

  f(String str, String errMsg, StackTrace? stkTrace) {
    logger.f(str, error: errMsg, stackTrace: stkTrace);
  }

  logLevel(Level lvl) {
    Logger.level = lvl;
  }
}

String userFunc() {
  return getCurrentMethodName();
}

String getCurrentMethodName() {
  final frames = StackTrace.current.toString().split('\n');
  final frame = frames.length > 1
      ? frames[1]
      : null; // 0 is current, 1 is caller
  if (frame != null) {
    final tokens = frame.split(' ');
    if (tokens.length > 1) {
      final methodField = tokens[tokens.length - 2];
      // Optionally remove class prefix: MyClass.myMethod → myMethod
      final parts = methodField.split('.');
      return parts.length > 1 ? parts[1] : methodField;
    }
  }
  return '';
}
