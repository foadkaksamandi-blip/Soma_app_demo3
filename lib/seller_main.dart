import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'common.dart';

void main() => runApp(const SellerApp());

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seller',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const SellerHome(),
    );
  }
}

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});
  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  int _balance = 500000; // پیش‌فرض دمو
  final _amountCtrl = TextEditingController();
  String _sellerId = 'seller-${_randId()}';
  String? _requestStr; // QR درخواست‌فروش
  final _secret = 'buyer-demo-secret'; // باید با خریدار هماهنگ باشد (دمو)

  static String _randId() => (100000 + Random().nextInt(900000)).toString();

  @override
  void initState() {
    super.initState();
    _load().then((_) => _genRequestQr());
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _balance = sp.getInt('seller_balance') ?? 500000;
      _sellerId = sp.getString('seller_id') ?? _sellerId;
    });
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('seller_balance', _balance);
    await sp.setString('seller_id', _sellerId);
  }

  void _genRequestQr([int? amount]) {
    final a = amount ?? int.tryParse(_amountCtrl.text.trim()) ?? 0;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final payload = QrPayload(
      type: 'sell_request',
      sellerId: _sellerId,
      amount: a,
      ts: ts,
      nonce: '${ts}-${Random().nextInt(1 << 32)}',
    );
    setState(() => _requestStr = jsonEncode(payload.toJson()));
  }

  Future<void> _scanPaymentProof() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
    if (res is String) {
      try {
        final p = QrPayload.fromJson(jsonDecode(res));
        if (p.type != 'payment_proof') {
          _toast('QR نامعتبر است.');
          return;
        }
        // اعتبارسنجی‌های پایه
        final expectedSig = makeSig(
          sellerId: p.sellerId,
          buyerId: p.buyerId,
          amount: p.amount,
          ts: p.ts,
          secret: _secret,
        );
        if (p.sig != expectedSig) {
          _toast('رسید معتبر نیست (امضا).');
          return;
        }
        if (p.sellerId != _sellerId) {
          _toast('رسید برای این فروشنده صادر نشده.');
          return;
        }
        // قبول پرداخت
        setState(() => _balance += p.amount);
        await _save();
        _toast('پرداخت تأیید شد: +${p.amount} تومان');
      } catch (_) {
        _toast('خواندن رسید ناموفق بود.');
      }
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('مبلغ فعلی: $_balance تومان',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'مبلغ جدید (تومان)', border: OutlineInputBorder()),
            onChanged: (_) => _genRequestQr(),
          ),
          const SizedBox(height: 12),
          if (_requestStr != null) ...[
            const Text('این QR را بدهید خریدار اسکن کند:'),
            const SizedBox(height: 10),
            Center(child: QrImageView(data: _requestStr!, size: 220)),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _scanPaymentProof,
            icon: const Icon(Icons.verified),
            label: const Text('اسکن رسید تأیید خریدار'),
          ),
          const SizedBox(height: 16),
          SelectableText('Seller ID: $_sellerId'),
        ],
      ),
    );
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _done = false;
  final controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن QR')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (_done) return;
          final b = capture.barcodes;
          if (b.isNotEmpty) {
            final raw = b.first.rawValue;
            if (raw != null) {
              _done = true;
              Navigator.pop(context, raw);
            }
          }
        },
      ),
    );
  }
}
