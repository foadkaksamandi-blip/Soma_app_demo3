// lib/seller_main.dart
import 'package:flutter/material.dart';
import 'services/ble_service.dart';

void main() {
  runApp(const SellerApp());
}

class SellerApp extends StatefulWidget {
  const SellerApp({super.key});

  @override
  State<SellerApp> createState() => _SellerAppState();
}

class _SellerAppState extends State<SellerApp> {
  final BleService _ble = BleService();
  bool _isAdvertising = false;
  String _deviceName = 'SOMA Seller';

  @override
  void initState() {
    super.initState();
    _ble.setDeviceName(_deviceName);
  }

  @override
  void dispose() {
    _ble.stopAdvertising();
    _ble.dispose();
    super.dispose();
  }

  Future<void> _toggleAdvertising() async {
    if (_isAdvertising) {
      await _ble.stopAdvertising();
      setState(() => _isAdvertising = false);
    } else {
      await _ble.startAdvertising(
        serviceUuid: '0000FEAA-0000-1000-8000-00805F9B34FB',
        manufacturerId: 0x004C,
        manufacturerData: [0x02, 0x15, 0xAA, 0xBB, 0xCC], // نمونه
        mode: AdvertiseMode.lowLatency,
        txPower: AdvertiseTxPower.high,
        includeDeviceName: true,
      );
      setState(() => _isAdvertising = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seller',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Seller (Peripheral)')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Device name: $_deviceName'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _toggleAdvertising,
                child: Text(_isAdvertising ? 'Stop Advertising' : 'Start Advertising'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
