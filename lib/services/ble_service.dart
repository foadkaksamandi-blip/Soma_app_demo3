// lib/services/ble_service.dart
// نسخه هماهنگ با flutter_ble_peripheral 1.2.6 و flutter_blue_plus 1.36.8

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

    // دقت کن Enum ها با حروف بزرگ شروع میشن در نسخه 1.2.6
    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      connectable: true,
      timeout: 0,
    );

    await _peripheral.start(settings: settings, data: data);
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }
}
