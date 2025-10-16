import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import '../models/ble_message.dart';

/// BLE واقعی به‌صورت «Advertise + Scan» (بدون اتصال GATT) فقط برای دمو.
/// - فروشنده: Advertise پیام درخواست پرداخت (REQ)
/// - خریدار: Scan و پرکردن فرم/پرداخت
/// - خریدار پس از پرداخت: Advertise رسید (RCPT)
/// - فروشنده: Scan رسید و واریز به موجودی
///
/// نکته: این روش روی همه‌ی گوشی‌ها یکسان نیست (به‌ویژه iOS). برای دمو Android کافی است.

class BleService {
  static const _advPrefix = 'SOMA|'; // به‌صورت LocalName در تبلیغ BLE

  final FlutterBluePlus _blue = FlutterBluePlus.instance;
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  StreamSubscription<ScanResult>? _scanSub;

  /// شروع تبلیغ (Seller: REQ  /  Buyer: RCPT)
  Future<void> startAdvertising(BleMessage msg) async {
    final name = _advPrefix + msg.encodeBase64();
    final data = AdvertiseData(
      includeDeviceName: true,
      localName: name.length <= 26 ? name : name.substring(0, 26),
    );
    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      timeout: 0, // بی‌نهایت تا زمانی که stopAdvertising صدا زده شود
    );
    await _peripheral.startAdvertising(
      advertiseData: data,
      advertiseSettings: settings,
    );
  }

  Future<void> stopAdvertising() async {
    try {
      await _peripheral.stopAdvertising();
    } catch (_) {}
  }

  /// اسکن تبلیغات و واکشی پیام‌هایی که با SOMA| شروع می‌شوند.
  Future<void> startScan({
    required void Function(BleMessage msg) onMessage,
  }) async {
    await _scanSub?.cancel();

    // اطمینان از روشن بودن BLE
    final isOn = await FlutterBluePlus.isOn;
    if (!isOn) {
      throw Exception('بلوتوث خاموش است');
    }

    await _blue.startScan(
      timeout: const Duration(seconds: 0), // تا توقف دستی
      androidUsesFineLocation: true,
    );

    _scanSub = _blue.scanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.localName ?? '';
        if (name.startsWith(_advPrefix)) {
          final payload = name.substring(_advPrefix.length);
          final msg = BleMessage.tryDecodeBase64(payload);
          if (msg != null) onMessage(msg);
        }
      }
    });
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await _blue.stopScan();
    } catch (_) {}
  }
}
