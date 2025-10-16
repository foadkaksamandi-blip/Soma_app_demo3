import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ فروشنده سوما',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Vazirmatn', // اگر فونت داری
      ),
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
  static const _balanceKey = 'seller_balance';
  static const _sellerIdKey = 'seller_id';

  int _balance = 500000; // پیش‌فرض دمو
  late String _sellerId;
  final _amountCtrl = TextEditingController();
  String? _currentReqJson; // محتوای QR درخواست پرداخت

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _balance = sp.getInt(_balanceKey) ?? _balance;
      _sellerId = sp.getString(_sellerIdKey) ?? 'seller-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    });
    await sp.setString(_sellerIdKey, _sellerId);
  }

  Future<void> _saveBalance() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_balanceKey, _balance);
  }

  String _formatToman(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write(',');
    }
    return b.toString();
  }

  void _buildPaymentRequest() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return;
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      _showSnack('مبلغ معتبر نیست');
      return;
    }
    final req = {
      'type': 'pay_req',
      'sellerId': _sellerId,
      'amount': amount,
      'reqId': const Uuid().v4(),
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    setState(() {
      _currentReqJson = jsonEncode(req);
    });
  }

  // اسکن رسید پرداخت خریدار و افزودن به موجودی
  Future<void> _scanBuyerReceipt() async {
    final code = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن رسید تایید خریدار')),
    );
    if (code == null) return;
    try {
      final map = jsonDecode(code);
      if (map is! Map || map['type'] != 'pay_ok') {
        _showSnack('رسید معتبر نیست');
        return;
      }
      if (map['sellerId'] != _sellerId) {
        _showSnack('رسید برای فروشنده دیگری است');
        return;
      }
      final amount = (map['amount'] as num).toInt();
      setState(() {
        _balance += amount;
      });
      await _saveBalance();
      _showSnack('مبلغ ${_formatToman(amount)} تومان دریافت شد');
    } catch (_) {
      _showSnack('خطا در خواندن رسید');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اپ فروشنده سوما')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('موجودی فعلی', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('${_formatToman(_balance)} تومان',
                        style: const TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'مبلغ جدید (تومان)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _buildPaymentRequest(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _buildPaymentRequest,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('تولید QR درخواست پرداخت'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 12),
            if (_currentReqJson != null) ...[
              const Text('این کُد را به خریدار نشان دهید:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Center(child: QrImageView(data: _currentReqJson!, size: 240)),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _scanBuyerReceipt,
              icon: const Icon(Icons.verified),
              label: const Text('اسکن رسید تایید خریدار'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 16),
            Text('Seller ID: $_sellerId', textAlign: TextAlign.left, style: const TextStyle(color: Colors.black54)),
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
  final ctrl = MobileScannerController();
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: MobileScanner(
          controller: ctrl,
          onDetect: (capture) {
            if (_done) return;
            final barcode = capture.barcodes.firstOrNull;
            final raw = barcode?.rawValue;
            if (raw != null) {
              _done = true;
              Navigator.of(context).pop(raw);
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
