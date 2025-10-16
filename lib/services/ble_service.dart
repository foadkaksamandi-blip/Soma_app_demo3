import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

/// سرویس BLE سازگار با نسخه‌های فعلی:
/// - فروشنده: Advertise با FlutterBlePeripheral
/// - خریدار: Scan با FlutterBluePlus
class BleService {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  StreamSubscription<List<ScanResult>>? _scanSub;

  /// شروع تبلیغ BLE با نام "SELLER:<sellerId>"
  Future<void> startAdvertisingSeller(String sellerId) async {
    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeBalanced,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      timeout: 0,
      connectable: true,
    );

    final data = AdvertiseData(
      includeDeviceName: true,
      localName: 'SELLER:$sellerId',
      // بایت‌های اختیاری جهت برچسب‌گذاری (SOMA)
      manufacturerId: 0xFFFF,
      manufacturerData: [0x53, 0x4F, 0x4D, 0x41],
    );

    await _peripheral.start(advertiseData: data, advertiseSettings: settings);
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }

  /// اسکن نتایج (خریدار): نتیجه‌ها را بده تا بیرون فیلتر شوند
  Future<void> startScan({
    required void Function(ScanResult r) onResult,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    await _scanSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((batch) {
      for (final r in batch) {
        onResult(r);
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);

    // در پایان تایم‌اوت، خود پکیج اسکن را متوقف می‌کند؛
    // اگر خواستی دستی هم متوقف کنی، stopScan را صدا بزن.
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
  }
}
