import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});
  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  final _amountCtrl = TextEditingController();
  double _balance = 500000;
  final String _sellerId = 'seller-${100000 + Random().nextInt(900000)}';
  Map<String, dynamic>? _lastPayload;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(num v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  void _buildQr() {
    final raw = _amountCtrl.text.trim().replaceAll(',', '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      _snack('مبلغ نامعتبر است');
      return;
    }
    final payload = {
      'type': 'pay_request',
      'sellerId': _sellerId,
      'amount': amount,
      'ts': DateTime.now().toIso8601String(),
    };
    setState(() => _lastPayload = payload);
  }

  void _applyDemoReceipt() {
    if (_lastPayload == null) {
      _snack('ابتدا QR پرداخت را تولید کنید');
      return;
    }
    final amount = (_lastPayload!['amount'] as num).toDouble();
    setState(() => _balance += amount);
    _snack('رسید تأیید دریافت شد (+${_fmt(amount)} تومان)');
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('موجودی فعلی', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text('${_fmt(_balance)} تومان',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.green)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ (تومان)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _buildQr,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('تولید QR پرداخت'),
            ),
            const SizedBox(height: 16),
            if (_lastPayload != null) ...[
              Center(
                child: QrImageView(
                  data: jsonEncode(_lastPayload),
                  size: 240,
                  version: QrVersions.auto,
                ),
              ),
              const SizedBox(height: 8),
              Text('این QR را به خریدار نشان دهید.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _applyDemoReceipt,
                icon: const Icon(Icons.verified),
                label: const Text('ثبت رسید خریدار (دمو)'),
              ),
            ],
            const SizedBox(height: 24),
            Text('Seller ID: $_sellerId', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
