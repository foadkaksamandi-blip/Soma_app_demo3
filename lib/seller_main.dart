import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'nearby_service.dart';

void main() => runApp(const SellerApp());

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ فروشنده سوما',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const SellerHomePage(),
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
  String? _qrPayload;
  late final String _sellerId;
  NearbyService? _nearby;
  String _nearbyStatus = 'خاموش';

  @override
  void initState() {
    super.initState();
    _sellerId = 'seller-${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _nearby?.stop();
    super.dispose();
  }

  void _buildQr() {
    final raw = _amountCtrl.text.replaceAll(',', '').trim();
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

  Future<void> _toggleNearby() async {
    if (_nearby?.isStarted == true) {
      await _nearby!.stop();
      setState(() => _nearbyStatus = 'خاموش');
      return;
    }
    _nearby = NearbyService(NearbyRole.seller, endpointName: _sellerId);
    _nearby!.connectionState.listen((s) => setState(() => _nearbyStatus = s));
    _nearby!.messages.listen((msg) {
      // انتظار پیام تأیید پرداخت از خریدار
      if (msg['type'] == 'payment_confirmed') {
        final amount = (msg['amount'] as num).toInt();
        setState(() => _balance += amount);
        _snack('تأیید پرداخت دریافت شد (+$amount)');
      }
    });
    await _nearby!.start();
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مبلغ فعلی :', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text('$_balance تومان',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ جدید (تومان)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _buildQr,
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('ایجاد QR'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_qrPayload != null) ...[
              Center(
                child: QrImageView(
                  data: _qrPayload!,
                  size: 240,
                ),
              ),
              const SizedBox(height: 8),
              Text('این QR را به خریدار نشان دهید.', textAlign: TextAlign.center),
            ],
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('وضعیت Nearby (بلوتوث)'),
              subtitle: Text(_nearbyStatus),
              trailing: FilledButton(
                onPressed: _toggleNearby,
                child: Text((_nearby?.isStarted ?? false) ? 'توقف' : 'شروع'),
              ),
            ),
            const SizedBox(height: 8),
            Text('Seller ID: $_sellerId', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
