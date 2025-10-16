import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() => runApp(const BuyerApp());

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'اپ خریدار سوما',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6C4AB6)),
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
  final buyerId = 'buyer-${Random().nextInt(90000) + 10000}';
  String? _payload;

  void _openScanner() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const _ScanPage()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _payload = result);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('QR دریافت شد')));
    }
  }

  void _pay() {
    if (_payload == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ابتدا QR فروشنده را اسکن کنید')));
      return;
    }
    final map = {
      for (final p in _payload!.split('|'))
        p.split('=')[0]: p.split('=').length > 1 ? p.split('=')[1] : ''
    };
    final amount = int.tryParse(map['amount'] ?? '0') ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('مبلغ نامعتبر در QR')));
      return;
    }
    if (balance < amount) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('موجودی کافی نیست')));
      return;
    }
    setState(() => balance -= amount);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('پرداخت $amount تومان انجام شد')));
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
              onPressed: _openScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('اسکن QR فروشنده'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _pay,
              child: const Text('پرداخت'),
            ),
            const SizedBox(height: 16),
            Text('Buyer ID: $buyerId'),
            if (_payload != null) Text('داده‌ی اسکن شده: $_payload'),
          ],
        ),
      ),
    );
  }
}

class _ScanPage extends StatefulWidget {
  const _ScanPage({super.key});
  @override
  State<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<_ScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اسکن QR')),
        body: MobileScanner(
          onDetect: (capture) {
            if (_done) return;
            final barcode = capture.barcodes.firstOrNull;
            final raw = barcode?.rawValue ?? '';
            if (raw.isNotEmpty) {
              _done = true;
              Navigator.pop(context, raw);
            }
          },
        ),
      ),
    );
  }
}
