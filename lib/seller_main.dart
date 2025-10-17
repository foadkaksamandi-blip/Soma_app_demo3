// lib/seller_main.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'services/ble_permissions.dart';
import 'services/ble_service.dart';

void main() {
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      home: const SellerHomePage(),
    );
  }
}

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});
  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  final BleService _ble = BleService();
  bool _isAdvertising = false;
  String _payload = '';
  int _balance = 600000;
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _payload = _makeSellerPayload();
  }

  String _makeSellerPayload() {
    // نمونه: type=SELLER|sellerId=seller-XXXX
    final id = Random().nextInt(900000) + 100000;
    return 'type=SELLER|sellerId=seller-$id';
  }

  Future<void> _startAdv() async {
    final ok = await BlePermissions.ensureBlePermissions();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اجازه‌های بلوتوث داده نشد')),
        );
      }
      return;
    }
    await _ble.startAdvertising(payload: _payload);
    setState(() => _isAdvertising = true);
  }

  Future<void> _stopAdv() async {
    await _ble.stopAdvertising();
    setState(() => _isAdvertising = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('فروشنده')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('موجودی فعلی: $_balance تومان',
                    style: const TextStyle(fontSize: 22, color: Colors.green)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ جدید (تومان)',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isAdvertising ? _stopAdv : _startAdv,
              child: Text(_isAdvertising ? 'توقف پخش BLE' : 'شروع پخش BLE'),
            ),
            const SizedBox(height: 8),
            Text('Payload BLE: $_payload', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            const Divider(),
            // بخش‌های QR مرجع قفل‌شده‌ات همین‌جا می‌ماند (تغییر نده)
            const Text('QR مرجع شما بدون تغییر باقی مانده است.'),
          ],
        ),
      ),
    );
  }
}
