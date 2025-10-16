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

  // داده‌های درخواست فروشنده (بعد از اسکن پر می‌شود)
  String? _sellerId;
  int? _amount;
  String? _tx;

  Map<String, String> _parsePayload(String s) {
    final parts = s.split('|');
    final map = <String, String>{};
    for (final p in parts) {
      final i = p.indexOf('=');
      if (i > 0) map[p.substring(0, i)] = p.substring(i + 1);
    }
    return map;
  }

  Future<void> _scanSeller() async {
    final data = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن فروشنده')),
    );
    if (data == null) return;

    // انتظار: type=REQUEST|sellerId=...|amount=...|tx=...
    final map = _parsePayload(data);
    if (map['type'] == 'REQUEST' &&
        map['sellerId'] != null &&
        map['amount'] != null &&
        map['tx'] != null) {
      setState(() {
        _sellerId = map['sellerId']!;
        _amount = int.tryParse(map['amount']!) ?? 0;
        _tx = map['tx']!;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('درخواست فروشنده دریافت شد')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('QR فروشنده معتبر نیست')));
    }
  }

  void _pay() {
    if (_sellerId == null || _amount == null || _tx == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ابتدا QR فروشنده را اسکن کنید')));
      return;
    }
    if (_amount! <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('مبلغ نامعتبر است')));
      return;
    }
    if (_balance < _amount!) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('موجودی کافی نیست')));
      return;
    }

    setState(() => _balance -= _amount!);

    // رسید نهایی که فروشنده باید اسکن کند
    final receiptPayload =
        'type=RECEIPT|sellerId=$_sellerId|buyerId=$_buyerId|amount=$_amount|tx=$_tx';

    // رسید را حتماً در صفحه‌ی جداگانه نمایش بده
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptPage(payload: receiptPayload),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('پرداخت انجام شد. رسید را به فروشنده نشان دهید.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepPurple;
    return Scaffold(
      appBar: AppBar(title: const Text('اپ خریدار سوما'), backgroundColor: themeColor),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BalanceCard(label: 'موجودی فعلی', amount: _balance),
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
            onPressed: _pay,
            child: const Text('پرداخت'),
          ),
          const SizedBox(height: 20),
          if (_sellerId != null && _amount != null)
            Text(
              'درخواست فروشنده: ${_amount} تومان — شناسه فروشنده: $_sellerId',
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

class _BalanceCard extends StatelessWidget {
  final String label;
  final int amount;
  const _BalanceCard({required this.label, required this.amount});

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
          final codes = capture.barcodes;
          if (codes.isNotEmpty) {
            _done = true;
            Navigator.of(context).pop(codes.first.rawValue);
          }
        },
      ),
    );
  }
}

/// صفحه‌ی نمایش رسید به‌صورت تمام‌صفحه
class ReceiptPage extends StatelessWidget {
  final String payload;
  const ReceiptPage({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رسید پرداخت')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(data: payload, size: 300),
            const SizedBox(height: 12),
            const Text('این QR را به فروشنده نشان دهید'),
          ],
        ),
      ),
    );
  }
}
