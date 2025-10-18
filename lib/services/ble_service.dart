// lib/services/ble_service.dart

import 'dart:async';

// نام‌گذاری برای جلوگیری از تداخل اسامی
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as rble;

/// سرویس BLE سازگار با flutter_blue_plus v1.36.8
/// نکته: APIهای اسکن در این نسخه استاتیک هستند (از روی کلاس فراخوانی می‌شوند).
class BleService {
  // اگر بعداً برای اتصال/Notify از reactive_ble استفاده کردید در دسترس است.
  final rble.FlutterReactiveBle _reactiveBle = rble.FlutterReactiveBle();

  bool _isAdvertising = false;

  /// شروع اسکن
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await fbp.FlutterBluePlus.startScan(timeout: timeout);
  }

  /// توقف اسکن
  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  /// استریم نتایج اسکن (از flutter_blue_plus)
  Stream<List<fbp.ScanResult>> get scanResults => fbp.FlutterBluePlus.scanResults;

  /// استریم وضعیت اسکن
  Stream<bool> get isScanning => fbp.FlutterBluePlus.isScanning;

  /// وضعیت فعلی اسکن
  bool get isScanningNow => fbp.FlutterBluePlus.isScanningNow;

  // ------------------------------------------------------------------
  // شبیه‌سازی تبلیغ برای سازگاری با کد قدیمی (در صورت عدم نیاز می‌توانید حذف کنید)
  // ------------------------------------------------------------------

  Future<void> startAdvertising() async {
    _isAdvertising = true;
    // تبلیغ واقعی در این پیاده‌سازی انجام نمی‌شود.
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
