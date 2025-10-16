import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

/// سرویس سادهٔ BLE که با نسخه‌های فعلی پکیج‌ها سازگار است.
/// - FlutterBlePeripheral: start/stop advertising (فروشنده)
/// - FlutterBluePlus: startScan/scanResults/stopScan (خریدار)
class BleService {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  StreamSubscription<List<ScanResult>>? _scanSub;

  /// شروع تبلیغ به‌عنوان فروشنده با الگوی نام "SELLER:<sellerId>"
  Future<void> startAdvertisingSeller(String sellerId) async {
    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeBalanced,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      timeout: 0, // بدون تایم‌اوت
      connectable: true,
    );

    final data = AdvertiseData(
      includeDeviceName: true,
      localName: 'SELLER:$sellerId',
      manufacturerId: 0xFFFF,
      manufacturerData: [0x53, 0x4F, 0x4D, 0x41], // "SOMA"
    );

    await _peripheral.start(advertiseData: data, advertiseSettings: settings);
  }

  /// توقف تبلیغ
  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }

  /// شروع اسکن به‌عنوان خریدار
  /// callback هر ScanResult را برمی‌گرداند تا خودت فیلتر کنی (مثلاً by name startsWith('SELLER:'))
  Future<void> startScan({
    required void Function(ScanResult r) onResult,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await _scanSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        onResult(r);
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);
  }

  /// توقف اسکن
  Future<void> stopScan() async {
    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
  }
}
