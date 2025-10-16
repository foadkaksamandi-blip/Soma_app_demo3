import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

/// لایهٔ سادهٔ BLE که با نسخه‌های فعلی پکیج‌ها سازگار است.
class BleService {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  StreamSubscription<List<ScanResult>>? _scanSub;

  /// شروع تبلیغ (Advertising) به‌عنوان فروشنده
  Future<void> startAdvertisingSeller(String sellerId) async {
    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeBalanced,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      timeout: 0, // بدون تایم‌اوت
      connectable: true,
    );

    // اسم دستگاه را طوری می‌گذاریم که قابل فیلتر کردن باشد (برای دمو)
    final data = AdvertiseData(
      includeDeviceName: true,
      localName: 'SELLER:$sellerId',
      // دادهٔ سازنده‌ی کوتاه برای علامت‌گذاری (اختیاری)
      manufacturerId: 0xFFFF,
      manufacturerData: [0x53, 0x4F, 0x4D, 0x41], // "SOMA"
    );

    await _peripheral.start(advertiseData: data, advertiseSettings: settings);
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }

  /// شروع اسکن به‌عنوان خریدار
  Future<void> startScan({
    required void Function(ScanResult r) onResult,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    // اول لیسنر را وصل می‌کنیم
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        onResult(r);
      }
    });

    // سپس اسکن را استارت می‌کنیم (متدهای کلاس-استاتیک هستند)
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
  }
}
