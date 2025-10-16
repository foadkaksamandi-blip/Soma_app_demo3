import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class BlePermissions {
  static Future<bool> ensureBlePermissions() async {
    if (!Platform.isAndroid) return true;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise, // برای advertise واقعی
      Permission.locationWhenInUse,  // برای برخی دستگاه‌های قدیمی
    ].request();

    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }
}
