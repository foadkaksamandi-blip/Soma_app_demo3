import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// درخواست و چک‌کردن پرمیشن‌های لازم برای BLE (Android 12+)
Future<bool> ensureBlePermissions() async {
  if (!Platform.isAndroid) {
    // iOS این پرمیشن‌ها را لازم ندارد (برای دمو ما فقط روی اندروید تست می‌کنیم)
    return true;
  }

  final List<Permission> perms = <Permission>[
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    // برای اسکن روی برخی دستگاه‌ها هنوز نیاز است:
    Permission.locationWhenInUse,
  ];

  // درخواست همه با هم
  final Map<Permission, PermissionStatus> statuses = await perms.request();

  // همه باید granted باشند
  return statuses.values.every((s) => s.isGranted);
}
