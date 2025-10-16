import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// درخواست مجوزهای لازم BLE برای اندروید.
/// روی iOS چیزی نیاز نیست (permission_handler خودش هندل می‌کند).
class BlePermissions {
  static Future<bool> ensureBlePermissions() async {
    if (!Platform.isAndroid) {
      // iOS یا پلتفرم‌های دیگر
      return true;
    }

    // از اندروید 12 به بعد مجوزهای جدید BLE لازم است.
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    // advertise را فعلاً نیاز نداریم؛ اگر خواستی تبلیغ اضافه شود:
    // final adv = await Permission.bluetoothAdvertise.request();

    // برای برخی گوشی‌ها هنوز location لازم است (به‌ویژه < Android 12)
    final loc = await Permission.locationWhenInUse.request();

    final ok = scan.isGranted && connect.isGranted && (loc.isGranted || loc.isLimited);
    return ok;
  }
}
