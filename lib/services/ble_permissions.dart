// lib/services/ble_permissions.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class BlePermissions {
  static Future<bool> ensureBlePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    // روی Android 12+ سه تا پرمیشن جدید داریم
    final perms = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse, // برای برخی دستگاه‌ها هنوز لازمه
    ];

    bool allGranted = true;
    for (final p in perms) {
      final status = await p.status;
      if (!status.isGranted) {
        final r = await p.request();
        if (!r.isGranted) {
          allGranted = false;
        }
      }
    }
    return allGranted;
  }
}
