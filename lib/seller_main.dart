import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const SellerApp());

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ فروشنده سوما',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'sans-serif',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const SellerHomePage(),
      localizationsDelegates: const [],
      supportedLocales: const [Locale('fa')],
    );
  }
}

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  final TextEditingController _amountCtrl = TextEditingController();
  int _balance = 500000;
  String? _qrPayload; // JSON برای درخواست پرداخت
  final String _sellerId = 'seller-${DateTime.now().millisecondsSinceEpoch % 100000}';

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _buildQr() {
    final raw = _amountCtrl.text.replaceAll(',', '').trim();
    if (raw.isEmpty) {
      _snack('لطفاً مبلغ را وارد کنید');
      return;
    }
    final amount = int.tryParse(raw);
    if (amount == null || amount <= 0) {
      _snack('مبلغ نامعتبر است');
      return;
    }
    final Map<String, dynamic> data = {
      'type': 'payment_request',
      'sellerId': _sellerId,
      'amount': amount,
      'ts': DateTime.now().toIso8601String(),
    };
    setState(() => _qrPayload = jsonEncode(data));
  }

  // وقتی خریدار پرداخت را تأیید کرد (در دمو به‌صورت دستی صدا می‌زنیم)
  void _applyOfflineReceipt(int amount) {
    setState(() => _balance += amount);
    _snack('پرداخت با موفقیت افزوده شد');
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مبلغ فعلی :',
                        style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text('$_balance تومان',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ جدید (تومان)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _buildQr,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('ایجاد کد QR برای پرداخت'),
            ),
            const SizedBox(height: 16),
            if (_qrPayload != null) ...[
              Center(
                child: QrImageView(
                  data: _qrPayload!,
                  version: QrVersions.auto,
                  size: 240,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'این QR را به خریدار نشان دهید تا اسکن و پرداخت را تأیید کند.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              // دکمه‌ی دمو برای اضافه شدن مبلغ پس از پرداخت
              OutlinedButton.icon(
                onPressed: () {
                  final map = jsonDecode(_qrPayload!) as Map<String, dynamic>;
                  _applyOfflineReceipt(map['amount'] as int);
                },
                icon: const Icon(Icons.verified),
                label: const Text('اسکن رسید تأیید خریدار (دمو)'),
              ),
            ],
            const SizedBox(height: 40),
            Text('Seller ID: $_sellerId', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
