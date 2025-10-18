// lib/services/ble_service.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // ------- Central (Scanner) -------

  /// شروع اسکن (API استاتیک در FBP 1.15.7)
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  /// توقف اسکن
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// استریم نتایج اسکن
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /// استریم وضعیت اسکن
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  // ------- Peripheral (Advertiser) -------

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  /// شروع تبلیغ — در v1.1.1 هیچ پارامتری قبول نمی‌کند
  Future<void> startAdvertising() async {
    await _peripheral.start();
  }

  /// توقف تبلیغ
  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }
}
