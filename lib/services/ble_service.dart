// lib/services/ble_service.dart
// نسخه هماهنگ با flutter_ble_peripheral 1.2.6 در GitHub CI

import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // --- BLE Central (Buyer) ---
  final FlutterBluePlus _blue = FlutterBluePlus.instance;

  Stream<List<ScanResult>> get scanResults => _blue.scanResults;

  Future<void> startScan({Duration? timeout}) async {
    await _blue.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    await _blue.stopScan();
  }

  // --- BLE Peripheral (Seller) ---
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  Future<void> startAdvertising({
    required Uint8List manufacturerData,
    int manufacturerId = 0xFFFF,
    String localName = 'SOMA-SELLER',
  }) async {
    final data = AdvertiseData(
      includeDeviceName: true,
      localName: localName,
      manufacturerId: manufacturerId,
      manufacturerData: manufacturerData,
    );

    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      connectable: true,
      timeout: 0,
    );

    // ⚠️ در نسخه CI فعلی متد فقط positional است، نه named:
    await _peripheral.start(data, settings);
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }
}
