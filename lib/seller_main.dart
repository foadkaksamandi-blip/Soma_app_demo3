import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'nearby_service.dart';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
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

  int _balance = 500000;
  late String _sellerId;
  final _amountCtrl = TextEditingController();
  String? _currentReqJson;

  // Nearby
  String? _connectedEndpoint;
  String get nickname => "SOMA-SELLER-$_sellerId";

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    NearbyService.stopAll();
    super.dispose();
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

  String _format(int v) {
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
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      _toast('مبلغ معتبر نیست');
      return;
    }
    final req = {
      'type': 'pay_req',
      'sellerId': _sellerId,
      'amount': amount,
      'reqId': const Uuid().v4(),
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    final str = jsonEncode(req);
    setState(() => _currentReqJson = str);

    // اگر به خریدار از طریق Nearby وصل هستیم، همین الان درخواست را بفرست
    if (_connectedEndpoint != null) {
      NearbyService.sendJson(_connectedEndpoint!, req);
      _toast('درخواست پرداخت از طریق بلوتوث ارسال شد');
    }
  }

  // مسیر QR: اسکن رسید پرداخت خریدار
  Future<void> _scanBuyerReceipt() async {
    final code = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن رسید تایید خریدار')),
    );
    if (code == null) return;
    _acceptReceipt(code);
  }

  // پذیرش رسید پرداخت (هم برای QR هم برای Nearby)
  void _acceptReceipt(String raw) async {
    try {
      final map = jsonDecode(raw);
      if (map is! Map || map['type'] != 'pay_ok' || map['sellerId'] != _sellerId) {
        _toast('رسید معتبر نیست');
        return;
      }
      final amount = (map['amount'] as num).toInt();
      setState(() => _balance += amount);
      await _saveBalance();
      _toast('پرداخت تایید شد: +${_format(amount)} تومان');
    } catch (_) {
      _toast('خطا در رسید');
    }
  }

  // شروع Advertising (فروشنده)
  Future<void> _startNearbyAdvertise() async {
    await NearbyService.startAdvertising(
      nickname: nickname,
      onConnInit: (id, info) async {
        await NearbyService.accept(id);
        setState(() => _connectedEndpoint = id);
        _toast('اتصال برقرار شد');
      },
      onPayload: (id, data) {
        // خریدار رسید پرداخت را برگرداند
        _acceptReceipt(data);
      },
    );
    _toast('بلوتوث امن فعال شد (حالت پذیرنده)');
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('موجودی فعلی', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('${_format(_balance)} تومان',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.teal)),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: _startNearbyAdvertise,
              icon: const Icon(Icons.bluetooth_connected),
              label: const Text('اتصال امن با بلوتوث (فروشنده)'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'مبلغ (تومان)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _buildPaymentRequest(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _buildPaymentRequest,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('تولید QR درخواست پرداخت'),
            ),
            const SizedBox(height: 12),
            if (_currentReqJson != null) ...[
              const Text('این کُد را به خریدار نشان دهید (یا از طریق بلوتوث ارسال شد):'),
              const SizedBox(height: 8),
              Center(child: QrImageView(data: _currentReqJson!, size: 240)),
            ],
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _scanBuyerReceipt,
              icon: const Icon(Icons.verified),
              label: const Text('اسکن رسید تایید خریدار (QR)'),
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
            final b = capture.barcodes;
            if (b.isNotEmpty) {
              final raw = b.first.rawValue;
              if (raw != null) {
                _done = true;
                Navigator.of(context).pop(raw);
              }
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
