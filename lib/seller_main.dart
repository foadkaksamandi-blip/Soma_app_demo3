import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() => runApp(const SellerApp());

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فروشنده',
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
      home: const SellerHomePage(),
    );
  }
}

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _balance = 500000;
  final _amountCtrl = TextEditingController();

  // شناسه فروشنده ثابت در این اجرا
  final String _sellerId = 'seller-${Random().nextInt(900000) + 100000}';

  // QR درخواست جاری که باید توسط خریدار اسکن شود
  String? _requestQrData;

  // برای اعتبارسنجی رسید خریدار
  String? _lastTx;     // tx آخرین درخواست
  int? _lastAmount;    // مبلغ آخرین درخواست

  // تولید payload درخواست پرداخت
  String _makeRequestPayload(int amount) {
    final tx = DateTime.now().millisecondsSinceEpoch.toString();
    _lastTx = tx;
    _lastAmount = amount;
    return 'type=REQUEST|sellerId=$_sellerId|amount=$amount|tx=$tx';
  }

  // اسکن رسید خریدار و افزایش موجودی در صورت اعتبار
  Future<void> _scanBuyerReceipt() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن رسید خریدار')),
    );
    if (result == null || result.isEmpty) return;

    // انتظار: type=RECEIPT|sellerId=...|buyerId=...|amount=...|tx=...
    final map = _parsePayload(result);
    final ok = map['type'] == 'RECEIPT' &&
        map['sellerId'] == _sellerId &&
        map['tx'] == _lastTx &&
        map['amount'] != null;

    if (!ok) {
      _snack('رسید نامعتبر است');
      return;
    }

    final amount = int.tryParse(map['amount']!) ?? 0;
    if (amount <= 0) {
      _snack('مبلغ رسید نامعتبر است');
      return;
    }

    setState(() {
      _balance += amount;
      // پس از مصرف رسید، درخواست جاری را می‌بندیم
      _requestQrData = null;
      _lastTx = null;
      _lastAmount = null;
    });
    _snack('مبلغ ${_fmt(amount)} تومان به موجودی اضافه شد');
  }

  Map<String, String> _parsePayload(String s) {
    final parts = s.split('|');
    final map = <String, String>{};
    for (final p in parts) {
      final i = p.indexOf('=');
      if (i > 0) map[p.substring(0, i)] = p.substring(i + 1);
    }
    return map;
  }

  String _fmt(int x) => x.toString();

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepPurple;
    return Scaffold(
      appBar: AppBar(
        title: const Text('فروشنده'),
        backgroundColor: themeColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _BalanceCard(label: 'موجودی فعلی', amount: _balance),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'مبلغ جدید (تومان)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              final amount = int.tryParse(_amountCtrl.text.trim());
              if (amount == null || amount <= 0) {
                _snack('مبلغ معتبر وارد کنید');
                return;
              }
              setState(() {
                _requestQrData = _makeRequestPayload(amount);
              });
            },
            child: const Text('تولید QR برای پرداخت'),
          ),

          if (_requestQrData != null) ...[
            const SizedBox(height: 18),
            Center(
              child: QrImageView(
                data: _requestQrData!,
                size: 260,
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('این QR را به خریدار نشان دهید')),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _scanBuyerReceipt,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('اسکن رسید خریدار'),
            ),
          ],

          const SizedBox(height: 28),
          Text('Seller ID: $_sellerId',
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
