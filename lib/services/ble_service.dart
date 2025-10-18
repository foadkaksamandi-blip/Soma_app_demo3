// lib/services/ble_service.dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// سرویس BLE سازگار با flutter_blue_plus v1.36.8
/// نکته مهم: APIهای اسکن در این نسخه استاتیک هستند و باید از روی کلاس
/// FlutterBluePlus فراخوانی شوند (نه instance).
class BleService {
  final FlutterReactiveBle _reactiveBle = FlutterReactiveBle();

  bool _isAdvertising = false;

  /// شروع اسکن
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
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

  /// وضعیت فعلی اسکن
  bool get isScanningNow => FlutterBluePlus.isScanningNow;

  // ------------------------------------------------------------------
  // شبیه‌سازی متدهای تبلیغ (برای سازگاری با کد قدیمی)
  // ------------------------------------------------------------------

  Future<void> startAdvertising() async {
    _isAdvertising = true;
    // این متد فعلاً تبلیغ واقعی انجام نمی‌دهد
  }

  Future<void> stopAdvertising() async {
    _isAdvertising = false;
  }

  // سازگاری با امضای قدیمی‌تر
  Future<void> start({dynamic settings, dynamic data}) async {
    await startAdvertising();
  }

  Future<void> stop() async {
    await stopAdvertising();
  }
}
