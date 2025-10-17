// lib/services/ble_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

class BleService {
  // ------ SELLER: Advertise ------
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  Future<void> startAdvertising({required String payload}) async {
    // payload را داخل manufacturerData می‌گذاریم (vendorId نمونه: 0x1234)
    final data = AdvertiseData(
      includeDeviceName: true,
      manufacturerId: 0x1234,
      manufacturerData: utf8.encode(payload),
    );

    // از تنظیمات پیش‌فرض استفاده می‌کنیم تا با نسخه‌ها تضاد نداشته باشد
    final settings = AdvertiseSettings(
      connectable: true,
    );

    await _peripheral.start(
      advertiseData: data,
      advertiseSettings: settings,
    );
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }

  // ------ BUYER: Scan ------
  final FlutterBluePlus _blue = FlutterBluePlus.instance;

  /// اسکن می‌کند و هر payload معتبر را از manufacturerData برمی‌گرداند.
  Stream<String> scanForSeller({Duration duration = const Duration(seconds: 8)}) async* {
    final controller = StreamController<String>();

    // جمع‌آوری نتایج
    final sub = _blue.scanResults.listen((results) {
      for (final r in results) {
        try {
          // vendorId همان 0x1234
          final m = r.advertisementData.manufacturerData[0x1234];
          if (m != null && m.isNotEmpty) {
            final decoded = utf8.decode(m);
            controller.add(decoded);
          }
        } catch (_) { /* ignore */ }
      }
    }, onError: controller.addError);

    await _blue.startScan(timeout: duration);

    // در پایان اسکن
    await Future.delayed(duration);
    await _blue.stopScan();
    await sub.cancel();

    await controller.close();
    yield* Stream.empty();
  }
}
