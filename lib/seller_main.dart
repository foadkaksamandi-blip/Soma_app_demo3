import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'services/ble_service.dart';

class SellerApp extends StatefulWidget {
  const SellerApp({super.key});
  @override
  State<SellerApp> createState() => _SellerAppState();
}

class _SellerAppState extends State<SellerApp> {
  final BleService _ble = BleService();
  StreamSubscription? _scanListen;

  @override
  void dispose() {
    _scanListen?.cancel();
    super.dispose();
  }

  Future<void> _startAdv() async {
    await _ble.startAdvertising(
      deviceName: 'SOMA Seller',
      mode: AdvertiseMode.lowLatency,
      txPower: AdvertiseTxPower.high,
      manufacturerId: 0xFFFF, // در صورت نیاز تغییر بده
      manufacturerData: [1, 2, 3, 4],
    );
  }

  Future<void> _stopAdv() => _ble.stopAdvertising();

  Future<void> _startScan() async {
    await _ble.startScan(timeout: const Duration(seconds: 5));
    _scanListen?.cancel();
    _scanListen = _ble.scanResults.listen((results) {
      // TODO: مدیریت نتایج
      // print(results.map((e) => e.device.remoteId.str).toList());
    });
  }

  Future<void> _stopScan() async {
    await _ble.stopScan();
    await _scanListen?.cancel();
    _scanListen = null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Vazirmatn'),
      home: Scaffold(
        appBar: AppBar(title: const Text('Seller')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton(onPressed: _startAdv, child: const Text('Start Advertising')),
              ElevatedButton(onPressed: _stopAdv, child: const Text('Stop Advertising')),
              const Divider(height: 32),
              ElevatedButton(onPressed: _startScan, child: const Text('Start Scan')),
              ElevatedButton(onPressed: _stopScan, child: const Text('Stop Scan')),
            ],
          ),
        ),
      ),
    );
  }
}
