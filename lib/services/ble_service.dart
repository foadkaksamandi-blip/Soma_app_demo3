import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // Central (Scanner)
  final FlutterBluePlus _blue = FlutterBluePlus.instance;
  StreamSubscription<List<ScanResult>>? _scanSub;

  Future<void> startScan({Duration? timeout}) async {
    // API جدید: پارامترها "named" هستند
    await _blue.startScan(timeout: timeout);
  }

  Stream<List<ScanResult>> get scanResults => _blue.scanResults;

  Future<void> stopScan() async {
    await _blue.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
  }

  // Peripheral (Advertiser)
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  Future<void> setDeviceName(String name) async {
    await _peripheral.setDeviceName(name);
  }

  Future<void> startAdvertising({
    String? deviceName,
    AdvertiseMode mode = AdvertiseMode.lowLatency,
    AdvertiseTxPower txPower = AdvertiseTxPower.high,
    List<int>? manufacturerData,
    int? manufacturerId,
    bool includeDeviceName = true,
    bool connectable = true,
  }) async {
    if (deviceName != null) {
      await _peripheral.setDeviceName(deviceName);
    }

    final data = AdvertiseData(
      includeDeviceName: includeDeviceName,
      manufacturerId: manufacturerId,
      manufacturerData: manufacturerData,
    );

    final settings = AdvertiseSettings(
      advertiseMode: mode,
      txPowerLevel: txPower,
      connectable: connectable,
    );

    // API درست: آرگومان‌ها باید "named" باشند
    await _peripheral.start(
      advertiseData: data,
      advertiseSettings: settings,
    );
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }
}
