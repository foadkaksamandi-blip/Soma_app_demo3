import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const SellerApp());

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

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
      title: 'فروشنده',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6C4AB6)),
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
  int balance = 500000;
  final sellerId = 'seller-${Random().nextInt(900000) + 100000}';
  final _ctrl = TextEditingController();
  String _qrPayload = '';

  void _makeQr() {
    final amount = int.tryParse(_ctrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مبلغ نامعتبر است')));
      return;
    }
    setState(() {
      _qrPayload = 'type=SELLER|amount=$amount|sellerId=$sellerId';
    });
  }

  @override
  Widget build(BuildContext context) {
    final numberStyle =
        Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.green[700]);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('فروشنده')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مبلغ فعلی :'),
                    const SizedBox(height: 8),
                    Text('$balance تومان', style: numberStyle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ جدید (تومان)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _makeQr,
              child: const Text('تولید QR برای پرداخت'),
            ),
            const SizedBox(height: 16),
            if (_qrPayload.isNotEmpty) ...[
              Center(
                child: QrImageView(
                  data: _qrPayload,
                  size: 260,
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('این QR را به خریدار نشان دهید')),
            ],
          ],
        ),
      ),
    );
  }
}
