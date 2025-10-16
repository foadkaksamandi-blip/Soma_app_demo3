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

  // داده های استخراج‌شده از QR فروشنده (REQUEST)
  String? _sellerIdFromRequest;
  String? _txFromRequest;
  int? _amountFromRequest;
  String? _rawRequest; // برای دیباگ

  // اسکن QR فروشنده و استخراج sellerId/tx/amount
  Future<void> _scanSellerRequest() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن QR فروشنده')),
    );
    if (result == null || result.isEmpty) return;

    final map = _parseKeyValues(result);
    // فرمت انتظار: type=REQUEST|sellerId=...|amount=...|tx=...
    final ok = map['type'] == 'REQUEST' &&
        map.containsKey('sellerId') &&
        map.containsKey('tx') &&
        map.containsKey('amount');

    if (!ok) {
      _snack('QR فروشنده نامعتبر است');
      return;
    }

    final amount = int.tryParse(map['amount'] ?? '');
    if (amount == null || amount <= 0) {
      _snack('مبلغ داخل QR فروشنده نامعتبر است');
      return;
    }

    setState(() {
      _sellerIdFromRequest = map['sellerId'];
      _txFromRequest = map['tx'];
      _amountFromRequest = amount;
      _rawRequest = result;
    });
  }

  // انجام پرداخت و تولید رسید
  void _pay() {
    if (_sellerIdFromRequest == null ||
        _txFromRequest == null ||
        _amountFromRequest == null) {
      _snack('ابتدا QR فروشنده را اسکن کنید');
      return;
    }

    final amount = _amountFromRequest!;
    if (_balance < amount) {
      _snack('موجودی کافی نیست');
      return;
    }

    setState(() {
      _balance -= amount;
    });

    // ساخت QR رسید با همان sellerId و tx درخواست فروشنده
    final receipt =
        'type=RECEIPT|sellerId=$_sellerIdFromRequest|buyerId=$_buyerId|amount=$amount|tx=$_txFromRequest';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptPage(receiptData: receipt),
      ),
    );
  }

  Map<String, String> _parseKeyValues(String s) {
    final map = <String, String>{};
    for (final part in s.split('|')) {
      final i = part.indexOf('=');
      if (i > 0) {
        map[part.substring(0, i)] = part.substring(i + 1);
      }
    }
    return map;
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepPurple;
    return Scaffold(
      appBar: AppBar(
        title: const Text('اپ خریدار سوما'),
        backgroundColor: themeColor,
      ),
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
            onPressed: _scanSellerRequest,
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
            onPressed: (_sellerIdFromRequest != null &&
                    _txFromRequest != null &&
                    _amountFromRequest != null)
                ? _pay
                : null,
            child: const Text('پرداخت'),
          ),

          if (_amountFromRequest != null) ...[
            const SizedBox(height: 16),
            Text('درخواست اسکن‌شده:',
                style: const TextStyle(color: Colors.black54)),
            Text(
              'sellerId=$_sellerIdFromRequest | amount=$_amountFromRequest | tx=$_txFromRequest',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],

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
            QrImageView(data: receiptData, size: 260),
            const SizedBox(height: 12),
            const Text('این QR را به فروشنده نشان دهید'),
            const SizedBox(height: 12),
            // خروجی خام برای دیباگ اگر لازم شد
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(receiptData,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
          ],
        ),
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
