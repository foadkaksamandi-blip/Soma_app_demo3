import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ خریدار سوما',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Vazirmatn',
      ),
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
  static const _balanceKey = 'buyer_balance';
  static const _buyerIdKey = 'buyer_id';

  int _balance = 800000; // پیش‌فرض دمو
  late String _buyerId;

  Map<String, dynamic>? _lastPay; // آخرین تراکنش پرداخت‌شده برای تولید رسید

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _balance = sp.getInt(_balanceKey) ?? _balance;
      _buyerId = sp.getString(_buyerIdKey) ?? 'buyer-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    });
    await sp.setString(_buyerIdKey, _buyerId);
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

  Future<void> _scanSellerQrAndPay() async {
    // اسکن QR فروشنده
    final raw = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن QR فروشنده')),
    );
    if (raw == null) return;

    // بررسی ساختار
    Map<String, dynamic> req;
    try {
      req = jsonDecode(raw);
      if (req['type'] != 'pay_req') throw 'bad';
    } catch (_) {
      _showSnack('کُد معتبر نیست');
      return;
    }

    final sellerId = req['sellerId'] as String;
    final amount = (req['amount'] as num).toInt();

    // نمایش دیالوگ تایید
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تایید پرداخت'),
          content: Text('پرداخت ${_formatToman(amount)} تومان به فروشنده: $sellerId انجام شود؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('پرداخت')),
          ],
        ),
      ),
    );

    if (ok != true) return;

    if (_balance < amount) {
      _showSnack('موجودی کافی نیست');
      return;
    }

    // کسر از موجودی و ذخیره
    setState(() {
      _balance -= amount;
      _lastPay = {
        'type': 'pay_ok',
        'sellerId': sellerId,
        'amount': amount,
        'reqId': req['reqId'],
        'buyerId': _buyerId,
        'receiptId': const Uuid().v4(),
        'ts': DateTime.now().millisecondsSinceEpoch,
      };
    });
    await _saveBalance();

    _showSnack('پرداخت انجام شد. رسید را به فروشنده نشان دهید.');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اپ خریدار سوما')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('موجودی فعلی', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('${_formatToman(_balance)} تومان',
                      style: const TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scanSellerQrAndPay,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('اسکن QR فروشنده'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 24),
            if (_lastPay != null) ...[
              const Text('رسید پرداخت را به فروشنده نشان دهید:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Center(child: QrImageView(data: jsonEncode(_lastPay), size: 240)),
            ],
            const SizedBox(height: 16),
            Text('Buyer ID: $_buyerId', textAlign: TextAlign.left, style: const TextStyle(color: Colors.black54)),
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
