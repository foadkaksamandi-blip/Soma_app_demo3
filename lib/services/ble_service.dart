import 'dart:async'; // 👈 اضافه شد برای StreamSubscription
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSub;

  /// شروع اسکن دستگاه‌های BLE
  void startScan(Function(DiscoveredDevice) onDeviceFound) {
    _scanSub = _ble.scanForDevices(withServices: []).listen(
      (device) => onDeviceFound(device),
      onError: (e) => print("❌ BLE scan error: $e"),
    );
  }

  /// توقف اسکن
  void stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
  }

  /// اتصال به دستگاه خاص
  Future<void> connectToDevice(String deviceId) async {
    await _ble.connectToDevice(id: deviceId).listen(
      (connectionState) {
        print("🔗 Connection state: ${connectionState.connectionState}");
      },
      onError: (e) => print("❌ Connection error: $e"),
    ).asFuture();
  }

  /// قطع ارتباط و پاک‌سازی منابع
  void dispose() {
    stopScan();
  }
}
