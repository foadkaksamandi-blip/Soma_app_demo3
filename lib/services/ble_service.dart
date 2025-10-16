import 'dart:async';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_message.dart';

class BleService {
  static const _prefix = 'SOMA|'; // داده را در localName تبلیغات می‌گذاریم

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  final FlutterBluePlus _blue = FlutterBluePlus.instance;
  StreamSubscription<List<ScanResult>>? _sub;

  Future<void> startAdvertising(BleMessage msg) async {
    final payload = _prefix + msg.encodeBase64();
    final data = AdvertiseData(
      includeDeviceName: true,
      localName: payload.length <= 26 ? payload : payload.substring(0, 26),
    );
    final settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      timeout: 0,
    );
    await _peripheral.startAdvertising(
      advertiseData: data,
      advertiseSettings: settings,
    );
  }

  Future<void> stopAdvertising() async {
    try { await _peripheral.stopAdvertising(); } catch (_) {}
  }

  Future<void> startScan({
    required void Function(BleMessage msg) onMessage,
  }) async {
    await _sub?.cancel();
    if (!await FlutterBluePlus.isOn) {
      throw Exception('بلوتوث خاموش است');
    }
    await _blue.startScan(timeout: const Duration(seconds: 0));
    _sub = _blue.scanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.localName ?? '';
        if (name.startsWith(_prefix)) {
          final msg = BleMessage.tryDecodeBase64(name.substring(_prefix.length));
          if (msg != null) onMessage(msg);
        }
      }
    });
  }

  Future<void> stopScan() async {
    await _sub?.cancel();
    _sub = null;
    try { await _blue.stopScan(); } catch (_) {}
  }
}
