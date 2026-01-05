import 'dart:developer';
import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._internal();
  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() {
    return _instance;
  }

  void error(String message) {
    if (kDebugMode) {
      log('Error: $message');
    } else {
      //FirebaseAnalytics.instance.logEvent(name: 'Error', parameters: {'message': message});
    }
  }

  void info(String message) {
    log('Info: $message');
  }

  void debug(String message) {
    log('Debug: $message');
  }
}
