// lib/services/ble_service.dart

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// سرویس BLE با سازگاری نام‌های قبلی پروژه
/// - اسکن با flutter_blue_plus
/// - متدهای start/stop به صورت no-op تا بیلد نشکند
class BleService {
  BleService();

  // اسکن (مرکزی) با FBP
  final FlutterBluePlus _blue = FlutterBluePlus.instance;

  // آماده برای پیاده‌سازی آتی peripheral/advertising با reactive_ble
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  /// نتایج اسکن (همان نام قدیمی پروژه)
  Stream<List<ScanResult>> get scanResults => _blue.scanResults;

  /// وضعیت اسکن به صورت Stream (نام جدید)
  Stream<bool> get isScanning => _blue.isScanning;

  /// وضعیت اسکن به صورت مقدار لحظه‌ای (برای سازگاری با نام قدیمی)
  bool get isScanningNow {
    // برخی نسخه‌ها isScanningNow دارند؛ اگر نداشت، از مقدار آخر isScanning استفاده کن
    try {
      return _blue.isScanningNow;
    } catch (_) {
      // fallback ساده: در اینجا true/false واقعی نداریم؛ مقدار امن بدهیم
      // اگر نیاز داری دقیق باشد، یک متغیر داخلی از stream نگه‌داری کن.
      return false;
    }
  }

  /// شروع اسکن با timeout (اسم و امضا مطابق استفاده‌های قبلی)
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    await _blue.startScan(timeout: timeout);
  }

  /// توقف اسکن
  Future<void> stopScan() async {
    await _blue.stopScan();
  }

  // ---------------------------------------------------------------------------
  // بخش زیر برای سازگاری با کدهای قبلی است که از peripheral/advertising استفاده می‌کردند.
  // چون flutter_ble_peripheral حذف شده، این‌ها فعلاً no-op هستند تا بیلد رد نشود.
  // اگر واقعاً به advertising نیاز داری، بعداً با flutter_reactive_ble پیاده‌سازی کن.
  // ---------------------------------------------------------------------------

  /// سازگار با امضای قدیمی: start(settings: ..., data: ...)
  Future<void> start({dynamic settings, dynamic data}) async {
    // TODO: در صورت نیاز، اینجا advertising با reactive_ble را پیاده‌سازی کن.
    return;
  }

  /// توقف advertising (فعلاً کاری نمی‌کند)
  Future<void> stop() async {
    return;
  }
}
