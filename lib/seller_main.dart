import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

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
      title: 'اپ فروشنده سوما',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: null, // اگر فونت فارسی داری اینجا بنویس: 'Vazirmatn'
      ),
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
  final TextEditingController _amountCtrl = TextEditingController();
  String? _qrPayload; // بر اساس مبلغ، QR تولید می‌کنیم

  void _makeQr() {
    final raw = _amountCtrl.text.trim().replaceAll(',', '');
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً مبلغ معتبر وارد کنید')),
      );
      return;
    }
    // پِی‌لود ساده: نوع=SELLER|amount=...|sellerId=...
    final sellerId = 'seller-210441'; // اگر به شکل پویا تولید می‌کنی همینجا عوض کن
    final payload = 'type=SELLER|amount=$amount|sellerId=$sellerId';
    setState(() => _qrPayload = payload);
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
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ جدید (تومان)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _makeQr,
                child: const Text('تولید QR برای پرداخت'),
              ),
            ),
            const SizedBox(height: 24),
            if (_qrPayload != null) ...[
              Center(
                child: QrImageView(
                  data: _qrPayload!,
                  size: 220,
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
