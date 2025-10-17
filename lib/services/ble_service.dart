import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

/// یک سرویس مشترک برای Buyer/Seller که با نسخه‌های جدید سازگاره
class BleService {
  // ---------- Buyer (Scanner) ----------
  StreamSubscription<List<ScanResult>>? _scanSub;

  Future<void> startScan({Duration? timeout}) async {
    // FlutterBluePlus در نسخه‌های جدید به صورت static استفاده می‌شود
    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidUsesFineLocation: false,
    );
    // اگر لازم داری حین اسکن به نتایج گوش بدی:
    _scanSub ??= FlutterBluePlus.scanResults.listen((results) {
      // اینجا هر جور خواستی هندل کن
      // مثال: print(results.map((e) => e.device.platformName).toList());
    });
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    await FlutterBluePlus.stopScan();
  }

  // ---------- Seller (Advertiser) ----------
  final _peripheral = FlutterBlePeripheral();

  /// شروع تبلیغ‌کردن BLE
  /// deviceName اختیاریه. manufacturerId و data هم اختیاری.
  Future<void> startAdvertising({
    String deviceName = 'SOMA-DEMO',
    int? manufacturerId,
    List<int>? data,
    int? txPowerLevelDbm, // مثلا 0 یا -4 یا 4
    bool includeDeviceName = true,
  }) async {
    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeBalanced,
      txPowerLevel:
          txPowerLevelDbm == null ? AdvertiseTxPower.advertiseTxPowerMedium
                                  : AdvertiseTxPower.advertiseTxPowerMedium,
      timeout: 0, // 0 یعنی بدون توقف خودکار
      connectable: false,
    );

    final advData = AdvertiseData(
      includeDeviceName: includeDeviceName,
      localName: deviceName,
      manufacturerId: manufacturerId,
      manufacturerData: data,
      // می‌تونی serviceUuid هم اضافه کنی
    );

    await _peripheral.startAdvertising(settings, advData);
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stopAdvertising();
  }

  // برای تمیزکاری عمومی
  Future<void> dispose() async {
    await stopScan();
    await stopAdvertising();
  }
}
