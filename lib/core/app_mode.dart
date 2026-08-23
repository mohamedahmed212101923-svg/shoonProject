import 'dart:io';
import 'package:flutter/foundation.dart';

class AppMode {
  static bool isServer = false;
  static const String serverIp = "192.168.2.1"; // IP السيرفر الثابت

  static Future<void> init() async {
    try {
      final interfaces = await NetworkInterface.list();
      bool found = false;
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address == serverIp) {
            found = true;
            break;
          }
        }
      }
      isServer = found;
    } catch (e) {
      isServer = false;
    }

    if (kDebugMode) {
      print("🛠️ وضع التشغيل الأولي: ${isServer ? "SERVER" : "CLIENT"}");
    }
  }
}
