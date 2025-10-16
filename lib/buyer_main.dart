import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'nearby_service.dart';

void main() => runApp(const BuyerApp());

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ خریدار سوما',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const BuyerHomePage(),
      supportedLocales: const [Locale('fa')],
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
  Map<String, dynamic>? _invoice;
  NearbyService? _nearby;
  String _nearbyStatus = 'خاموش';
  late final String _buyerId;

  @override
  void initState() {
    super.initState();
    _buyerId = 'buyer-${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  @override
  void dispose() {
    _nearby?.stop();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _onScan(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['type'] != 'payment_request') {
        _snack('کد معتبر نیست');
        return;
      }
      setState(() => _invoice = map);
      _confirmPayment(map);
    } catch (_) {
      _snack('کد معتبر نیست');
    }
  }

  Future<void> _confirmPayment(Map<String, dynamic> invoice) async {
    final amount = (invoice['amount'] as num).toInt();
    if (amount > _balance) {
      _snack('موجودی کافی نیست');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأیید پرداخت'),
          content: Text('پرداخت $amount تومان به ${invoice['sellerId']} انجام شود؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('پرداخت')),
          ],
        ),
      ),
    );

    if (ok == true) {
      setState(() => _balance -= amount);
      _snack('پرداخت انجام شد (دمو).');

      // اگر به فروشنده متصل هستیم، اعلان تأیید را بفرستیم
      if (_nearby?.isConnected == true) {
        await _nearby!.sendJson({
          'type': 'payment_confirmed',
          'amount': amount,
          'buyerId': _buyerId,
          'ts': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<void> _toggleNearby() async {
    if (_nearby?.isStarted == true) {
      await _nearby!.stop();
      setState(() => _nearbyStatus = 'خاموش');
      return;
    }
    _nearby = NearbyService(NearbyRole.buyer, endpointName: _buyerId);
    _nearby!.connectionState.listen((s) => setState(() => _nearbyStatus = s));
    _nearby!.messages.listen((msg) {
      // درصورت نیاز پیام‌های فروشنده را اینجا بگیریم
    });
    await _nearby!.start();
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('موجودی فعلی', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text('$_balance تومان',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scanner(onRaw: _onScan),
                ));
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('اسکن QR فروشنده'),
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.bluetooth_searching),
              title: const Text('وضعیت Nearby (بلوتوث)'),
              subtitle: Text(_nearbyStatus),
              trailing: FilledButton(
                onPressed: _toggleNearby,
                child: Text((_nearby?.isStarted ?? false) ? 'توقف' : 'شروع'),
              ),
            ),
            if (_invoice != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text('درخواست پرداخت: ${_invoice!['amount']} تومان'),
                  subtitle: Text('فروشنده: ${_invoice!['sellerId']}'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text('Buyer ID: $_buyerId', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class Scanner extends StatelessWidget {
  const Scanner({super.key, required this.onRaw});
  final void Function(String raw) onRaw;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اسکن کنید')),
        body: MobileScanner(
          onDetect: (capture) {
            final codes = capture.barcodes;
            if (codes.isEmpty) return;
            final raw = codes.first.rawValue;
            if (raw != null && raw.isNotEmpty) {
              Navigator.of(context).pop();
              onRaw(raw);
            }
          },
        ),
      ),
    );
  }
}
