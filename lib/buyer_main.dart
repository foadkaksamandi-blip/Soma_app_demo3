import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'models/ble_message.dart';
import 'services/ble_service.dart';

void main() => runApp(const BuyerApp());

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ خریدار سوما',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const BuyerHomePage(),
    );
  }
}

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  int _balance = 800000;
  final _buyerId = 'buyer-${Random().nextInt(900000) + 100000}';

  String? _sellerId;
  int? _amount;
  String? _tx;
  String? _receiptPayload;

  // BLE
  final BleService _ble = BleService();
  bool _bleScanning = false;

  @override
  void dispose() {
    _ble.stopScan();
    super.dispose();
  }

  Future<void> _scanSellerQr() async {
    final data = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن فروشنده')),
    );
    if (data == null) return;
    final map = _kv(data);
    final ok = map['type'] == 'REQUEST' &&
        map['sellerId'] != null && map['amount'] != null && map['tx'] != null;
    if (!ok) {
      _snack('QR فروشنده معتبر نیست');
      return;
    }
    setState(() {
      _sellerId = map['sellerId']!;
      _amount = int.tryParse(map['amount']!) ?? 0;
      _tx = map['tx']!;
      _receiptPayload = null;
    });
  }

  void _pay() {
    if (_sellerId == null || _amount == null || _tx == null) {
      _snack('ابتدا QR فروشنده را اسکن کنید');
      return;
    }
    if (_amount! <= 0 || _balance < _amount!) {
      _snack('مبلغ نامعتبر یا موجودی ناکافی');
      return;
    }
    setState(() {
      _balance -= _amount!;
      _receiptPayload =
          'type=RECEIPT|sellerId=$_sellerId|buyerId=$_buyerId|amount=$_amount|tx=$_tx';
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ReceiptPage(data: _receiptPayload!)),
    );
  }

  // ---- BLE: پیدا کردن درخواست فروشنده (بدون QR) ----
  Future<void> _scanSellerByBle() async {
    await _ble.stopScan();
    setState(() => _bleScanning = true);
    await _ble.startScan(onMessage: (msg) {
      if (msg.type == BleMsgType.payRequest) {
        setState(() {
          _sellerId = msg.partyId;
          _amount = msg.amount;
          _tx = msg.note ?? DateTime.now().millisecondsSinceEpoch.toString();
          _bleScanning = false;
        });
        _ble.stopScan();
        _snack('درخواست فروشنده دریافت شد: ${msg.amount} تومان');
      }
    });
  }

  Map<String, String> _kv(String s) {
    final m = <String, String>{};
    for (final p in s.split('|')) {
      final i = p.indexOf('=');
      if (i > 0) m[p.substring(0, i)] = p.substring(i + 1);
    }
    return m;
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPay = _sellerId != null && _amount != null && _tx != null;

    return Scaffold(
      appBar: AppBar(title: const Text('اپ خریدار سوما')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _balanceCard('موجودی فعلی', _balance),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _scanSellerQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('اسکن QR فروشنده'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _bleScanning ? null : _scanSellerByBle,
            child: Text(_bleScanning ? 'درحال اسکن بلوتوث…' : 'یافتن فروشنده با بلوتوث (آزمایشی)'),
          ),

          if (_sellerId != null && _amount != null) ...[
            const SizedBox(height: 12),
            Text('sellerId=$_sellerId | amount=$_amount | tx=$_tx',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ],

          const SizedBox(height: 16),
          FilledButton(
            onPressed: canPay ? _pay : null,
            child: const Text('پرداخت'),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(String label, int amount) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text('$amount تومان',
              style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
        ]),
      );
}

class _ReceiptPage extends StatelessWidget {
  final String data;
  const _ReceiptPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رسید پرداخت')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          QrImageView(data: data, size: 280),
          const SizedBox(height: 8),
          const Text('این QR را به فروشنده نشان دهید'),
          const SizedBox(height: 8),
          Text(data, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      ),
    );
  }
}

class _ScanPage extends StatefulWidget {
  final String title;
  const _ScanPage({required this.title});

  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  bool _done = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final code = capture.barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            _done = true;
            Navigator.of(context).pop(code);
          }
        },
      ),
    );
  }
}
