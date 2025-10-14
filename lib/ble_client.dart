import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SomaBleClient {
  // همین UUIDها باید با سرور (فروشنده) یکی باشند:
  static const String serviceUuid = "0000A0A0-0000-1000-8000-00805F9B34FB";
  static const String writeCharUuid = "0000A0A1-0000-1000-8000-00805F9B34FB";

  BluetoothDevice? device;
  BluetoothCharacteristic? writeChar;

  Future<bool> connect() async {
    await FlutterBluePlus.stopScan();
    final scanSub = FlutterBluePlus.onScanResults.listen((results) async {
      for (final r in results) {
        final uuids = r.advertisementData.serviceUuids.map((e) => e.toUpperCase()).toList();
        if (uuids.contains(serviceUuid)) {
          device = r.device;
          await FlutterBluePlus.stopScan();
          try {
            await device!.connect(timeout: const Duration(seconds: 10));
          } catch (_) {}
          final services = await device!.discoverServices();
          for (final s in services) {
            if (s.uuid.toString().toUpperCase() == serviceUuid) {
              for (final c in s.characteristics) {
                if (c.uuid.toString().toUpperCase() == writeCharUuid && c.properties.write) {
                  writeChar = c;
                  return;
                }
              }
            }
          }
        }
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    await scanSub.cancel();
    return writeChar != null;
  }

  Future<bool> sendJson(Map<String, dynamic> payload) async {
    if (writeChar == null) return false;
    final data = utf8.encode(jsonEncode(payload));
    await writeChar!.write(data, withoutResponse: true);
    return true;
  }

  Future<void> disconnect() async {
    try { await device?.disconnect(); } catch (_) {}
  }
}
