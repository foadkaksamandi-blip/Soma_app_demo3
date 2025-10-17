// lib/seller_main.dart
// صفحه‌ی ساده برای نقش فروشنده که آگهی BLE را با flutter_ble_peripheral شروع/متوقف می‌کند.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'services/ble_service.dart';

class SellerApp extends StatefulWidget {
  const SellerApp({super.key});

  @override
  State<SellerApp> createState() => _SellerAppState();
}

class _SellerAppState extends State<SellerApp> {
  final BleService _ble = BleService();
  bool _isAdvertising = false;
  String _status = 'Idle';

  // داده‌ی دموی قابل ارسال داخل manufacturerData (به دلخواه خودت عوض کن)
  Uint8List _buildManufacturerPayload() {
    // مثلا یک JSON ساده از سفارش/مبلغ و…:
    final map = {
      'type': 'SOMA_DEMO',
      'role': 'SELLER',
      'amount': 120000, // Rial
      'currency': 'IRR',
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    final bytes = utf8.encode(jsonEncode(map));
    return Uint8List.fromList(bytes);
  }

  Future<void> _start() async {
    try {
      setState(() {
        _status = 'Starting advertising...';
      });

      await _ble.startAdvertising(
        manufacturerData: _buildManufacturerPayload(),
        // manufacturerId دلخواه، فقط طرف مقابل باید بدونه با چه آی‌دی پارس کنه
        manufacturerId: 0xFFFF,
        localName: 'SOMA-SELLER',
        mode: AdvertiseMode.lowLatency,
        txPower: AdvertiseTxPower.high,
        connectable: true,
        timeoutSeconds: 0,
      );

      setState(() {
        _isAdvertising = true;
        _status = 'Advertising';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _stop() async {
    try {
      await _ble.stopAdvertising();
      setState(() {
        _isAdvertising = false;
        _status = 'Stopped';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Seller',
      home: Scaffold(
        appBar: AppBar(title: const Text('SOMA Seller')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Status: $_status'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isAdvertising ? null : _start,
                child: const Text('Start Advertising'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isAdvertising ? _stop : null,
                child: const Text('Stop Advertising'),
              ),
              const SizedBox(height: 24),
              const Text(
                'نکته: در نسخه‌ی جدید flutter_ble_peripheral از start/stop استفاده می‌شود '
                'و setDeviceName یا startAdvertising موجود نیست.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
