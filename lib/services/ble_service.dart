import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // ----------- خریدار (Scanner) -----------
  final FlutterBluePlus _blue = FlutterBluePlus.instance;
  StreamSubscription<List<ScanResult>>? _scanSub;

  Future<void> startScan({Duration timeout = const Duration(seconds: 8)}) async {
    await _blue.startScan(timeout: timeout);
    _scanSub?.cancel();
    _scanSub = _blue.scanResults.listen((results) {
      for (final r in results) {
        if (kDebugMode) {
          debugPrint("SCAN → ${r.device.platformName} (${r.device.remoteId}) rssi=${r.rssi}");
        }
      }
    });
  }

  Future<void> stopScan() async {
    await _blue.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
  }

  Stream<List<ScanResult>> get scanResults => _blue.scanResults;

  // ----------- فروشنده (Advertiser) -----------
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  bool _isAdvertising = false;

  Future<void> startAdvertise({
    String name = "SOMA-DEMO",
    int manufacturerId = 0xFFFF,
    List<int> manufacturerData = const [0x53, 0x4F, 0x4D, 0x41],
  }) async {
    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      timeout: 0,
      connectable: false,
    );

    final data = AdvertiseData(
      includeDeviceName: true,
      manufacturerId: manufacturerId,
      manufacturerData: manufacturerData,
    );

    await _peripheral.setDeviceName(name);
    await _peripheral.startAdvertising(settings, data);
    _isAdvertising = true;
    if (kDebugMode) debugPrint("ADVERTISE → started ($name)");
  }

  Future<void> stopAdvertise() async {
    if (_isAdvertising) {
      await _peripheral.stopAdvertising();
      _isAdvertising = false;
      if (kDebugMode) debugPrint("ADVERTISE → stopped");
    }
  }

  bool get isAdvertising => _isAdvertising;
}
