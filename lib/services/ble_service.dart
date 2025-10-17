import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // -------------------- Buyer (Central) --------------------
  // نسخه 1.36.8 از APIهای static استفاده می‌کند.
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> startScan({Duration? timeout}) async {
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // -------------------- Seller (Peripheral) --------------------
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  Future<void> startAdvertising({
    required Uint8List manufacturerData,
    int manufacturerId = 0xFFFF,
    String localName = 'SOMA-SELLER',
  }) async {
    final data = AdvertiseData(
      includeDeviceName: true,
      localName: localName,
      manufacturerId: manufacturerId,
      manufacturerData: manufacturerData,
    );

    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      connectable: true,
      timeout: 0,
    );

    // نسخه فعلی متد start از پارامترهای نام‌دار استفاده می‌کند
    await _peripheral.start(
      advertiseData: data,
      advertiseSettings: settings,
    );
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }
}
