// lib/services/ble_service.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // ------- Central (Scanner) -------

  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  // ------- Peripheral (Advertiser) -------

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  /// در v1.1.1 باید advertiseData پاس داده شود
  Future<void> startAdvertising() async {
    // حداقلِ لازم برای کامپایل/اجرا
    await _peripheral.start(advertiseData: AdvertiseData());
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }
}
