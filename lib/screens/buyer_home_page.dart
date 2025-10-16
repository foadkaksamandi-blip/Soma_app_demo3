import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});
  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  double _balance = 800000;
  final String _buyerId = 'buyer-${10000 + Random().nextInt(90000)}';
  Map<String, dynamic>? _lastReceipt;

  String _fmt(num v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _scanSellerQr() async {
    final data = await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(builder: (_) => const _ScanPage()),
    );
    if (!mounted || data == null) return;

    // انتظار: {"type":"pay_request","sellerId":"...","amount":...}
    final ok = data['type'] == 'pay_request' && data['amount'] != null;
    if (!ok) {
      _snack('QR فروشنده معتبر نیست');
      return;
    }
    final amount = (data['amount'] as num).toDouble();

    final agree = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأیید پرداخت'),
          content: Text('پرداخت مبلغ ${_fmt(amount)} تومان انجام شود؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('پرداخت')),
          ],
        ),
      ),
    );
    if (agree != true) return;

    if (_balance < amount) {
      _snack('موجودی کافی نیست');
      return;
    }

    setState(() {
      _balance -= amount;
      _lastReceipt = {
        'type': 'pay_receipt',
        'buyerId': _buyerId,
        'sellerId': data['sellerId'],
        'amount': amount,
        'ts': DateTime.now().toIso8601String(),
      };
    });
    _snack('پرداخت انجام شد');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('خریدار')),
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
            FilledButton.icon(
              onPressed: _scanSellerQr,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('اسکن QR فروشنده'),
            ),
            const SizedBox(height: 24),
            if (_lastReceipt != null) ...[
              const Text('رسید تأیید پرداخت (نمایشی برای فروشنده):'),
              const SizedBox(height: 12),
              Center(
                child: QrImageView(
                  data: jsonEncode(_lastReceipt),
                  size: 220,
                  version: QrVersions.auto,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'مبلغ: ${_fmt((_lastReceipt!['amount'] as num).toDouble())} تومان',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Text('Buyer ID: $_buyerId', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _ScanPage extends StatefulWidget {
  const _ScanPage();

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اسکن QR')),
        body: MobileScanner(
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
            facing: CameraFacing.back,
          ),
          onDetect: (cap) {
            if (_handled || cap.barcodes.isEmpty) return;
            final raw = cap.barcodes.first.rawValue ?? '';
            if (raw.isEmpty) return;
            try {
              final data = jsonDecode(raw) as Map<String, dynamic>;
              _handled = true;
              Navigator.pop(context, data);
            } catch (_) {
              // JSON نبود → اجازه بده کاربر دوباره اسکن کند
            }
          },
        ),
      ),
    );
  }
}
