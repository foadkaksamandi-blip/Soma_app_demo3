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
  final BleService _bleService = BleService();
  bool _advertising = false;

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  Future<void> _toggleAdvertising() async {
    if (_advertising) {
      await _bleService.stopAdvertising();
    } else {
      await _bleService.startAdvertising();
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
              Text(
                _advertising ? 'Advertising Active' : 'Idle',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleAdvertising,
                child: Text(_advertising ? 'Stop Advertising' : 'Start Advertising'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
