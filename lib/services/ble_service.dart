import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final FlutterBlePeripheral peripheral = FlutterBlePeripheral();

  StreamSubscription? _scanSubscription;

  // --- برای حالت خریدار (اسکن BLE) ---
  void startScan({Duration timeout = const Duration(seconds: 5)}) {
    stopScan(); // جلوگیری از تداخل
    flutterBlue.startScan(timeout: timeout);
  }

  void stopScan() {
    flutterBlue.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => flutterBlue.scanResults;

  void listenToScan(void Function(List<ScanResult>) onResult) {
    _scanSubscription = scanResults.listen(onResult);
  }

  void dispose() {
    _scanSubscription?.cancel();
    stopScan();
  }

  // --- برای حالت فروشنده (پریفرال / تبلیغ) ---
  Future<void> startAdvertising() async {
    final advertiseData = AdvertiseData(
      includeDeviceName: true,
      manufacturerId: 1234,
      manufacturerData: [1, 2, 3, 4],
      serviceUuid: "0000FEAA-0000-1000-8000-00805F9B34FB",
    );

    await peripheral.start(advertiseData);
  }

  Future<void> stopAdvertising() async {
    await peripheral.stop();
  }
}
