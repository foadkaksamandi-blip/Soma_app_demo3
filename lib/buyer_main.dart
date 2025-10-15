import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'common.dart';

void main() => runApp(const BuyerApp());

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ خریدار سوما',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const BuyerHome(),
    );
  }
}

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});
  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  int _balance = 800000; // پیش‌فرض دمو
  String? _lastProof;   // آخرین رسید تولید شده برای نمایش QR رسید
  final _secret = 'buyer-demo-secret'; // برای دمو

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _balance = sp.getInt('buyer_balance') ?? 800000;
    });
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('buyer_balance', _balance);
  }

  Future<void> _scanSellerQr() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
    if (res is String) {
      try {
        final payload = QrPayload.fromJson(jsonDecode(res));
        if (payload.type != 'sell_request') {
          _show('QR نامعتبر است.');
          return;
        }
        if (_balance < payload.amount) {
          _show('موجودی کافی نیست.');
          return;
        }
        // کسر مبلغ
        setState(() => _balance -= payload.amount);
        await _save();

        // ساخت رسید پرداخت برای اسکن فروشنده
        final ts = DateTime.now().millisecondsSinceEpoch;
        final proof = QrPayload(
          type: 'payment_proof',
          sellerId: payload.sellerId,
          buyerId: 'buyer-${_deviceId()}',
          amount: payload.amount,
          ts: ts,
          nonce: '${ts}-${Random().nextInt(1 << 32)}',
          sig: makeSig(
            sellerId: payload.sellerId,
            buyerId: 'buyer-${_deviceId()}',
            amount: payload.amount,
            ts: ts,
            secret: _secret,
          ),
        );
        final str = jsonEncode(proof.toJson());
        setState(() => _lastProof = str);
        _show('پرداخت انجام شد. کد تأیید را به فروشنده نشان دهید.');
      } catch (_) {
        _show('QR خوانا نبود.');
      }
    }
  }

  String _deviceId() => 'demo'; // برای دمو ثابت است

  void _show(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اپ خریدار سوما')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('موجودی فعلی', style: TextStyle(fontSize: 18)),
                  Text('$_balance تومان',
                      style:
                          const TextStyle(fontSize: 28, color: Colors.green)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _scanSellerQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('اسکن QR فروشنده'),
          ),
          const SizedBox(height: 20),
          if (_lastProof != null) ...[
            const Text('کد تأیید پرداخت را به فروشنده نشان دهید:',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Center(child: QrImageView(data: _lastProof!, size: 220)),
          ],
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
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final raw = barcodes.first.rawValue;
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
