// lib/services/ble_service.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // ---------- Scanner (Buyer/Seller – برای اسکن) ----------
  final FlutterBluePlus _blue = FlutterBluePlus.instance;
  StreamSubscription<List<ScanResult>>? _scanSub;

  Stream<List<ScanResult>> get scanResults => _blue.scanResults;

  Future<void> startScan({Duration timeout = const Duration(seconds: 8)}) async {
    // اگر در حال اسکن است، اول متوقف کن
    if (_blue.isScanningNow) {
      await _blue.stopScan();
    }
    await _blue.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    // متد هنوز در نسخه فعلی وجود داره
    await _blue.stopScan();
  }

  void listenToScanResults(void Function(List<ScanResult>) onData) {
    _scanSub?.cancel();
    _scanSub = scanResults.listen(onData, onError: (e) {});
  }

  Future<void> dispose() async {
    await _scanSub?.cancel();
    if (_blue.isScanningNow) {
      await _blue.stopScan();
    }
  }

  // ---------- Peripheral (Seller – برای تبلیغ/ادورتایز) ----------
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  Future<void> setDeviceName(String name) async {
    await _peripheral.setDeviceName(name);
  }

  /// شروع ادورتایز با پارامترهای نام‌دار (در v1.2.6 اجباری است)
  Future<void> startAdvertising({
    String serviceUuid = '0000FEAA-0000-1000-8000-00805F9B34FB',
    int manufacturerId = 0x004C, // نمونه: Apple company ID – فقط نمونه است
    List<int>? manufacturerData,
    AdvertiseMode mode = AdvertiseMode.lowLatency,
    AdvertiseTxPower txPower = AdvertiseTxPower.high,
    bool includeDeviceName = true,
  }) async {
    final settings = AdvertiseSettings(
      advertiseMode: mode,
      txPowerLevel: txPower,
      connectable: true,
      timeout: 0,
    );

    // نوع باید Uint8List باشد
    final Uint8List? mfData =
        (manufacturerData == null) ? null : Uint8List.fromList(manufacturerData);

    final data = AdvertiseData(
      serviceUuid: serviceUuid,
      includeDeviceName: includeDeviceName,
      manufacturerId: manufacturerId,
      manufacturerData: mfData,
    );

    // در v1.2.6 امضا نام‌دار است:
    await _peripheral.start(settings: settings, data: data);
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }
}
