import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'nearby_service.dart';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
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

  int _balance = 800000;
  late String _buyerId;

  Map<String, dynamic>? _lastPay;
  // Nearby
  final List<MapEntry<String, String>> _found = []; // endpointId → nickname
  String? _connectedEndpoint;
  String get nickname => "SOMA-BUYER-$_buyerId";

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
      _buyerId = sp.getString(_buyerIdKey) ?? 'buyer-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    });
    await sp.setString(_buyerIdKey, _buyerId);
  }

  Future<void> _save() async {
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

  // مسیر QR (fallback)
  Future<void> _scanSellerQrAndPay() async {
    final raw = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const _ScanPage(title: 'اسکن QR فروشنده')),
    );
    if (raw == null) return;
    _handlePayReq(raw, viaNearby: false, fromEndpoint: null);
  }

  // Nearby: کشف فروشنده و اتصال
  Future<void> _startNearbyDiscovery() async {
    _found.clear();
    setState(() {});
    await NearbyService.startDiscovery(
      nickname: nickname,
      onEndpointFound: (id, name) {
        _found.add(MapEntry(id, name));
        setState(() {});
      },
      onEndpointLost: (id) {
        _found.removeWhere((e) => e.key == id);
        setState(() {});
      },
      onPayload: (id, data) {
        // Seller یک pay_req فرستاد
        _handlePayReq(data, viaNearby: true, fromEndpoint: id);
      },
    );
    _toast('جستجوی فروشنده آغاز شد');
  }

  Future<void> _connectToSeller(String endpointId) async {
    await NearbyService.requestConnection(
      endpointId: endpointId,
      onConnInit: (id, info) async {
        await NearbyService.accept(id);
        setState(() => _connectedEndpoint = id);
        _toast('اتصال برقرار شد');
      },
    );
  }

  Future<void> _handlePayReq(String raw, {required bool viaNearby, String? fromEndpoint}) async {
    Map<String, dynamic> req;
    try {
      req = jsonDecode(raw);
      if (req['type'] != 'pay_req') throw 'bad';
    } catch (_) {
      _toast('درخواست معتبر نیست');
      return;
    }
    final sellerId = req['sellerId'] as String;
    final amount = (req['amount'] as num).toInt();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تایید پرداخت'),
          content: Text('پرداخت ${_format(amount)} تومان به فروشنده $sellerId انجام شود؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('پرداخت')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    if (_balance < amount) {
      _toast('موجودی کافی نیست');
      return;
    }

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
    await _save();

    if (viaNearby && fromEndpoint != null) {
      await NearbyService.sendJson(fromEndpoint, _lastPay!);
      _toast('رسید پرداخت برای فروشنده ارسال شد');
    } else {
      _toast('پرداخت انجام شد. رسید QR را به فروشنده نشان دهید.');
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('موجودی فعلی', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('${_format(_balance)} تومان',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.green)),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: _startNearbyDiscovery,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('پیدا کردن فروشنده (بلوتوث امن)'),
            ),
            const SizedBox(height: 8),

            if (_found.isNotEmpty)
              Card(
                child: Column(
                  children: _found
                      .map((e) => ListTile(
                            leading: const Icon(Icons.storefront),
                            title: Text(e.value),
                            subtitle: Text("Endpoint: ${e.key}"),
                            trailing: FilledButton(
                              onPressed: () => _connectToSeller(e.key),
                              child: const Text('اتصال'),
                            ),
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _scanSellerQrAndPay,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('پرداخت از طریق اسکن QR فروشنده'),
            ),
            const SizedBox(height: 20),

            if (_lastPay != null) ...[
              const Text('رسید پرداخت (برای QR در صورت نیاز):'),
              const SizedBox(height: 8),
              Center(child: QrImageView(data: jsonEncode(_lastPay), size: 240)),
            ],

            const SizedBox(height: 12),
            Text('Buyer ID: $_buyerId', style: const TextStyle(color: Colors.black54)),
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
