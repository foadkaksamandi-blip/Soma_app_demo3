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
  final String _sellerId = 'seller-${Random().nextInt(900000) + 100000}';

  String? _requestQr; // type=REQUEST|sellerId=...|amount=...|tx=...
  String? _lastTx;    // برای اعتبارسنجی رسید

  String _buildRequest(int amount) {
    final tx = DateTime.now().millisecondsSinceEpoch.toString();
    _lastTx = tx;
    return 'type=REQUEST|sellerId=$_sellerId|amount=$amount|tx=$tx';
  }

  Future<void> _scanReceipt() async {
    final data = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن رسید خریدار')),
    );
    if (data == null || data.isEmpty) return;

    // انتظار: type=RECEIPT|sellerId=...|buyerId=...|amount=...|tx=...
    final map = _kv(data);
    final ok = map['type'] == 'RECEIPT' &&
        map['sellerId'] == _sellerId &&
        map['tx'] == _lastTx &&
        (int.tryParse(map['amount'] ?? '0') ?? 0) > 0;

    if (ok) {
      final paid = int.tryParse(map['amount']!)!;
      setState(() {
        _balance += paid;
        _requestQr = null;
        _lastTx = null;
      });
      _snack('واریز ${_fmt(paid)} تومان انجام شد');
    } else {
      _snack('رسید نامعتبر است');
    }
  }

  Map<String, String> _kv(String s) {
    final m = <String, String>{};
    for (final p in s.split('|')) {
      final i = p.indexOf('=');
      if (i > 0) m[p.substring(0, i)] = p.substring(i + 1);
    }
    return m;
  }

  String _fmt(int x) => x.toString();
  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepPurple;
    return Scaffold(
      appBar: AppBar(title: const Text('فروشنده'), backgroundColor: themeColor),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Balance(label: 'موجودی فعلی', amount: _balance),
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
              final a = int.tryParse(_amountCtrl.text.trim());
              if (a == null || a <= 0) {
                _snack('مبلغ معتبر وارد کنید');
                return;
              }
              setState(() => _requestQr = _buildRequest(a));
            },
            child: const Text('تولید QR برای پرداخت'),
          ),
          if (_requestQr != null) ...[
            const SizedBox(height: 18),
            Center(child: QrImageView(data: _requestQr!, size: 260)),
            const SizedBox(height: 8),
            const Center(child: Text('این QR را به خریدار نشان دهید')),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _scanReceipt,
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
