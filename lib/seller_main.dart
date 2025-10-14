import 'package:flutter/material.dart';

void main() => runApp(const SellerApp());

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Seller',
      home: Scaffold(
        appBar: AppBar(title: const Text('آپ آفلاین سوما - فروشنده')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text('فروشنده: پذیرش پرداخت آفلاین', textAlign: TextAlign.right),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(onPressed: () {}, child: const Text('نمایش QR مبلغ')),
                  ElevatedButton(onPressed: () {}, child: const Text('اتصال بلوتوث امن')),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'مبلغ خرید',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'کد تراکنش (اعلامی خریدار)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),
              Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('وضعیت دریافت/تسویه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
