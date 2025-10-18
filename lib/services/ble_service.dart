// lib/services/ble_service.dart
//
// نسخه‌ای که با flutter_blue_plus 1.15.7 و flutter_ble_peripheral 1.1.1 سازگار است.
// هیچ متد/enum جدیدی (مثل isScanningNow یا settings:) استفاده نشده تا با CI شما بخورد نگیرد.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // --- Central (Scanner) ---
  final FlutterBluePlus _blue = FlutterBluePlus.instance;
  StreamSubscription<List<ScanResult>>? _scanSub;

  /// شروع اسکن
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    // API این نسخه: startScan({Duration timeout})
    await _blue.startScan(timeout: timeout);
  }

  /// توقف اسکن
  Future<void> stopScan() async {
    await _blue.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
  }

  /// استریم نتایج اسکن (API این نسخه موجود است)
  Stream<List<ScanResult>> get scanResults => _blue.scanResults;

  /// استریم وضعیت اسکن (در این نسخه isScanning به‌صورت Stream<bool> است)
  Stream<bool> get isScanning => _blue.isScanning;

  // --- Peripheral (Advertiser) ---
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  /// شروع تبلیغ (بدون استفاده از پارامتر settings: چون در 1.1.1 وجود ندارد)
  Future<void> startAdvertising({
    String? deviceName,
    int manufacturerId = 0x1234,
    List<int> manufacturerData = const <int>[],
    bool includeTxPowerLevel = false,
    bool includeDeviceName = true,
  }) async {
    // در این نسخه، start فقط یک AdvertiseData دریافت می‌کند.
    final data = AdvertiseData(
      includeDeviceName: includeDeviceName && deviceName != null,
      manufacturerId: manufacturerId,
      manufacturerData: Uint8List.fromList(manufacturerData),
      // در این نسخه، AdvertiseSettings مجزا یا enum های mode/txPower الزامی نیستند.
      // اگر deviceName غیر null باشد، روی بعضی دستگاه‌ها از نام سیستم استفاده می‌شود.
    );

    await _peripheral.start(data);
  }

  /// توقف تبلیغ
  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }
}
