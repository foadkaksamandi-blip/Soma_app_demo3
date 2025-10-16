import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  final String _buyerId = 'buyer-${Random().nextInt(900000) + 100000}';

  String? _sellerId;
  int? _amount;
  String? _tx;

  Future<void> _scanSeller() async {
    final data = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن فروشنده')),
    );
    if (data == null) return;

    // انتظار: type=REQUEST|sellerId=...|amount=...|tx=...
    final map = _kv(data);
    final ok = map['type'] == 'REQUEST' &&
        map['sellerId'] != null &&
        map['amount'] != null &&
        map['tx'] != null;

    if (!ok) {
      _snack('QR فروشنده معتبر نیست');
      return;
    }
    final a = int.tryParse(map['amount']!) ?? 0;
    if (a <= 0) {
      _snack('مبلغ داخل QR نامعتبر است');
      return;
    }
    setState(() {
      _sellerId = map['sellerId']!;
      _amount = a;
      _tx = map['tx']!;
    });
  }

  void _pay() {
    if (_sellerId == null || _amount == null || _tx == null) {
      _snack('ابتدا QR فروشنده را اسکن کنید');
      return;
    }
    if (_balance < _amount!) {
      _snack('موجودی کافی نیست');
      return;
    }
    setState(() => _balance -= _amount!);

    final receipt =
        'type=RECEIPT|sellerId=$_sellerId|buyerId=$_buyerId|amount=$_amount|tx=$_tx';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptPage(receiptData: receipt),
      ),
    );
    _snack('پرداخت انجام شد — رسید را به فروشنده نشان دهید');
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
    final themeColor = Colors.deepPurple;
    return Scaffold(
      appBar: AppBar(title: const Text('اپ خریدار سوما'), backgroundColor: themeColor),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Balance(label: 'موجودی فعلی', amount: _balance),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _scanSeller,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('اسکن QR فروشنده'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: (_sellerId != null && _amount != null && _tx != null) ? _pay : null,
            child: const Text('پرداخت'),
          ),
          const SizedBox(height: 16),
          if (_sellerId != null && _amount != null)
            Text(
              'sellerId=$_sellerId | amount=$_amount | tx=$_tx',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          const SizedBox(height: 28),
          Text('Buyer ID: $_buyerId',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class ReceiptPage extends StatelessWidget {
  final String receiptData;
  const ReceiptPage({super.key, required this.receiptData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رسید پرداخت')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(data: receiptData, size: 280),
            const SizedBox(height: 8),
            const Text('این QR را به فروشنده نشان دهید'),
            const SizedBox(height: 10),
            Text(receiptData,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  final String label;
  final int amount;
  const _Balance({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 8),
          Text('${amount} تومان',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.green)),
        ],
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
