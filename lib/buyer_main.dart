import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// اگر اسکنر داری، ایمپورت مربوطه رو فعال کن.
//// import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [
        Locale('fa'),
        Locale('en'),
      ],
      // نکته مهم: این لیست «const» نباشد
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'اپ خریدار سوما',
      theme: ThemeData(useMaterial3: true),
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
  int balance = 800000;
  String? _lastScan;

  void _simulateScan() async {
    // این فقط شبیه‌ساز اسکنه؛ اگر اسکنر واقعی داری همینجا جایگزین کن.
    // خروجی باید payload فروشنده باشه: type=SELLER|amount=...|sellerId=...
    setState(() => _lastScan = 'type=SELLER|amount=10000|sellerId=seller-210441');
  }

  void _pay() {
    if (_lastScan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا QR فروشنده را اسکن کنید')),
      );
      return;
    }
    final parts = {
      for (final p in _lastScan!.split('|'))
        p.split('=')[0]: p.split('=').length > 1 ? p.split('=')[1] : ''
    };
    final amount = int.tryParse(parts['amount'] ?? '0') ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ نامعتبر در QR')),
      );
      return;
    }
    if (balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موجودی کافی نیست')),
      );
      return;
    }
    setState(() {
      balance -= amount;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('پرداخت $amount تومان انجام شد')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberStyle =
        Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.green[700]);

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
                    const Text('موجودی فعلی'),
                    const SizedBox(height: 8),
                    Text('$balance تومان', style: numberStyle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _simulateScan, // این را با اسکنر واقعی جایگزین کن
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('اسکن QR فروشنده'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _pay,
              child: const Text('پرداخت'),
            ),
            if (_lastScan != null) ...[
              const SizedBox(height: 16),
              Text('داده‌ی اسکن شده: $_lastScan'),
            ],
          ],
        ),
      ),
    );
  }
}
