// lib/services/ble_service.dart
// سرویس BLE برای هر دو نقش (Buyer به‌عنوان مرکزی/اسکنر) و (Seller به‌عنوان پیرامونی/تبلیغ‌کننده)

import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // -------- Buyer (Central / Scanner) --------
  final FlutterBluePlus _blue = FlutterBluePlus.instance;

  /// استریم نتایج اسکن (لیست ScanResult)
  Stream<List<ScanResult>> get scanResults => _blue.scanResults;

  /// شروع اسکن
  Future<void> startScan({Duration? timeout}) async {
    // timeout اختیاریه؛ اگر دادی همون اعمال میشه
    await _blue.startScan(timeout: timeout);
  }

  /// توقف اسکن
  Future<void> stopScan() async {
    await _blue.stopScan();
  }

  // -------- Seller (Peripheral / Advertiser) --------
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  /// شروع تبلیغ BLE با داده‌ی کارخانه (manufacturerData)
  /// توجه: manufacturerData باید Uint8List باشد.
  Future<void> startAdvertising({
    required Uint8List manufacturerData,
    int manufacturerId = 0xFFFF,
    String localName = 'SOMA-SELLER',
    AdvertiseMode mode = AdvertiseMode.lowLatency,
    AdvertiseTxPower txPower = AdvertiseTxPower.high,
    bool connectable = true,
    int timeoutSeconds = 0, // 0 یعنی بدون تایم‌اوت
  }) async {
    final data = AdvertiseData(
      includeDeviceName: true,
      localName: localName,
      manufacturerId: manufacturerId,
      manufacturerData: manufacturerData,
    );

    final settings = AdvertiseSettings(
      advertiseMode: mode,
      txPowerLevel: txPower,
      connectable: connectable,
      timeout: timeoutSeconds,
    );

    await _peripheral.start(
      advertiseData: data,
      advertiseSettings: settings,
    );
  }

  /// توقف تبلیغ
  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }
}
