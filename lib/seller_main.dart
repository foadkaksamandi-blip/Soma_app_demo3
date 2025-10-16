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
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
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
  String? _requestQrData; // QR درخواست فعلی
  String _sellerId = 'seller-${Random().nextInt(900000) + 100000}';

  // دیتاهای آخرین تراکنش در فروشنده (برای اعتبارسنجی رسید)
  String? _lastTx;
  int? _lastAmount;

  String _buildRequestPayload(int amount) {
    final tx = DateTime.now().millisecondsSinceEpoch.toString();
    _lastTx = tx;
    _lastAmount = amount;
    return 'type=REQUEST|sellerId=$_sellerId|amount=$amount|tx=$tx';
  }

  // اسکن رسید خریدار
  Future<void> _scanReceipt() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن رسید خریدار')),
    );
    if (result == null) return;

    // انتظار: type=RECEIPT|sellerId=...|buyerId=...|amount=...|tx=...
    final map = _parsePayload(result);
    final ok = map['type'] == 'RECEIPT' &&
        map['sellerId'] == _sellerId &&
        map['tx'] == _lastTx &&
        map['amount'] != null;

    if (ok) {
      final paid = int.tryParse(map['amount']!) ?? 0;
      setState(() {
        _balance += paid;
        // بعد از مصرف رسید، ریست تراکنش
        _requestQrData = null;
        _lastTx = null;
        _lastAmount = null;
      });
      _showSnack('واریز انجام شد (+${_fmt(paid)} تومان)');
    } else {
      _showSnack('رسید نامعتبر است');
    }
  }

  Map<String, String> _parsePayload(String s) {
    final parts = s.split('|');
    final map = <String, String>{};
    for (final p in parts) {
      final i = p.indexOf('=');
      if (i > 0) {
        map[p.substring(0, i)] = p.substring(i + 1);
      }
    }
    return map;
  }

  String _fmt(int x) => x.toString();

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
          _BalanceCard(label: 'مبلغ فعلی', amount: _balance),
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
                _showSnack('مبلغ معتبر وارد کنید');
                return;
              }
              setState(() {
                _requestQrData = _buildRequestPayload(amount);
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
          Text('$label :', style: const TextStyle(fontSize: 16, color: Colors.black54)),
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
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            _done = true;
            Navigator.of(context).pop(barcodes.first.rawValue);
          }
        },
      ),
    );
  }
}
