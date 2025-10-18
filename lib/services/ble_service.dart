// lib/services/ble_service.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// سرویس BLE سازگار با flutter_blue_plus v1.36.8
/// شامل اسکن، توقف، و متدهای شبیه‌سازی‌شده برای advertising
class BleService {
  final FlutterBluePlus _ble = FlutterBluePlus.instance;
  final FlutterReactiveBle _reactiveBle = FlutterReactiveBle();

  bool _isAdvertising = false;

  /// شروع اسکن (Scan for nearby BLE devices)
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await _ble.startScan(timeout: timeout);
  }

  /// توقف اسکن
  Future<void> stopScan() async {
    await _ble.stopScan();
  }

  /// استریم نتایج اسکن
  Stream<List<ScanResult>> get scanResults => _ble.scanResults;

  /// استریم وضعیت اسکن (true/false)
  Stream<bool> get isScanning => _ble.isScanning;

  /// وضعیت فعلی اسکن (boolean)
  bool get isScanningNow => _ble.isScanningNow;

  // ------------------------------------------------------------------
  // شبیه‌سازی متدهای startAdvertising / stopAdvertising برای سازگاری
  // ------------------------------------------------------------------

  Future<void> startAdvertising() async {
    _isAdvertising = true;
    // این متد فقط برای سازگاری وجود دارد (فعلاً تبلیغ واقعی انجام نمی‌دهد)
  }

  Future<void> stopAdvertising() async {
    _isAdvertising = false;
  }

  // سازگاری با امضای قدیمی‌تر (ble.start و ble.stop)
  Future<void> start({dynamic settings, dynamic data}) async {
    await startAdvertising();
  }

  Future<void> stop() async {
    await stopAdvertising();
  }
}
