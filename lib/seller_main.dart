import 'package:flutter/material.dart';
import 'services/ble_service.dart';

void main() {
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SellerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SellerScreen extends StatefulWidget {
  const SellerScreen({super.key});

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  final ble = BleService();
  bool _advertising = false;

  @override
  void dispose() {
    ble.stopAdvertising();
    super.dispose();
  }

  Future<void> _toggleAdvertise() async {
    if (_advertising) {
      await ble.stopAdvertising();
    } else {
      await ble.startAdvertising(
        deviceName: "SOMA-DEMO",
        manufacturerId: 0xFFFF,
        data: [0x53, 0x4F, 0x4D, 0x41], // 'SOMA'
      );
    }
    setState(() => _advertising = !_advertising);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Mode (Advertiser)')),
      body: Center(
        child: ElevatedButton(
          onPressed: _toggleAdvertise,
          child: Text(_advertising ? 'Stop Advertising' : 'Start Advertising'),
        ),
      ),
    );
  }
}
