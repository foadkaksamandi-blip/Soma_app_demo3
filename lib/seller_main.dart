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
  bool _advertising = false;

  @override
  void dispose() {
    _ble.dispose();
    super.dispose();
  }

  Future<void> _toggleAdv() async {
    if (_advertising) {
      await _ble.stopAdvertising();
    } else {
      await _ble.startAdvertising();
    }
    setState(() => _advertising = !_advertising);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Seller',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('Seller (Peripheral Mode)')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_advertising ? 'Advertising: ON' : 'Advertising: OFF',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _toggleAdv,
                child: Text(_advertising ? 'Stop Advertising' : 'Start Advertising'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
