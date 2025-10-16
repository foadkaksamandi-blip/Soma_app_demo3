import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// درخواست مجوزهای لازم برای اسکن/پخش BLE.
/// در iOS این تابع true برمی‌گرداند (دمو ما فعلاً روی اندروید تست می‌شود).
Future<bool> ensureBlePermissions() async {
  if (!Platform.isAndroid) return true;

  final perms = <Permission>[
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse, // برای برخی دستگاه‌ها هنوز لازم است
  ];

  final results = await perms.request();
  return results.values.every((s) => s.isGranted);
}
