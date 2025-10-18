import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // --- حالت خریدار (اسکن) ---
  /// شروع اسکن (با تایم‌اوت پیش‌فرض 5 ثانیه)
  void startScan({Duration timeout = const Duration(seconds: 5)}) {
    // در 1.15.7 متدها را از خود کلاس صدا می‌زنیم
    FlutterBluePlus.startScan(timeout: timeout);
  }

  /// توقف اسکن
  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  /// استریم نتایج اسکن
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  StreamSubscription<List<ScanResult>>? _scanSub;
  void listenToScan(void Function(List<ScanResult>) onData) {
    _scanSub?.cancel();
    _scanSub = scanResults.listen(onData);
  }

  // --- حالت فروشنده (تبلیغ پریفرال) ---
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  Future<void> startAdvertising() async {
    final data = AdvertiseData(
      includeDeviceName: true,
      // در این نسخه manufacturerData باید Uint8List باشد
      manufacturerId: 1234,
      manufacturerData: Uint8List.fromList([1, 2, 3, 4]),
      serviceUuid: "0000FEAA-0000-1000-8000-00805F9B34FB",
    );

    // در 1.1.1 پارامتر نام‌دار است:
    await _peripheral.start(advertiseData: data);
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }

  void dispose() {
    _scanSub?.cancel();
    stopScan();
  }
}
