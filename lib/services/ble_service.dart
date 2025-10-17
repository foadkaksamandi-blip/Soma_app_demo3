import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  final FlutterBluePlus _blue = FlutterBluePlus.instance;
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isAdvertising = false;

  // ----------- خریدار (اسکن دستگاه‌ها) -----------
  Future<void> startScan() async {
    try {
      await _blue.startScan(timeout: const Duration(seconds: 8));
      _scanSubscription = _blue.scanResults.listen((results) {
        for (final r in results) {
          if (kDebugMode) {
            debugPrint("🔍 Found device: ${r.device.platformName} (${r.device.remoteId})");
          }
        }
      });
    } catch (e) {
      debugPrint("❌ Scan error: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await _blue.stopScan();
      await _scanSubscription?.cancel();
    } catch (e) {
      debugPrint("❌ Stop scan error: $e");
    }
  }

  Stream<List<ScanResult>> get scanResults => _blue.scanResults;

  // ----------- فروشنده (ارسال داده BLE) -----------
  Future<void> startAdvertising({
    String deviceName = "SOMA-DEMO",
    int manufacturerId = 0xFFFF,
    List<int> data = const [0x53, 0x4F, 0x4D, 0x41],
  }) async {
    try {
      await _peripheral.setDeviceName(deviceName);

      final settings = AdvertiseSettings(
        advertiseMode: AdvertiseMode.advertiseModeLowLatency,
        txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
        timeout: 0,
        connectable: true,
      );

      final advData = AdvertiseData(
        includeDeviceName: true,
        manufacturerId: manufacturerId,
        manufacturerData: Uint8List.fromList(data),
      );

      await _peripheral.startAdvertising(settings, advData);
      _isAdvertising = true;
      debugPrint("📡 Advertising started as $deviceName");
    } catch (e) {
      debugPrint("❌ Advertising error: $e");
    }
  }

  Future<void> stopAdvertising() async {
    try {
      if (_isAdvertising) {
        await _peripheral.stopAdvertising();
        _isAdvertising = false;
        debugPrint("📴 Advertising stopped");
      }
    } catch (e) {
      debugPrint("❌ Stop advertise error: $e");
    }
  }

  bool get isAdvertising => _isAdvertising;
}
