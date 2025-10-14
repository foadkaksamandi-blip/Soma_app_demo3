import 'package:flutter/material.dart';

void main() => runApp(const BuyerApp());

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Buyer',
      home: Scaffold(
        appBar: AppBar(title: const Text('آپ آفلاین سوما - خریدار')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text('موجودی خریدار: 0', textAlign: TextAlign.right),
              const SizedBox(height: 12),
              const Text('انتخاب نوع اتصال/پرداخت', textAlign: TextAlign.right),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(onPressed: () {}, child: const Text('اسکن QR')),
                  ElevatedButton(onPressed: () {}, child: const Text('اتصال بلوتوث')),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'مبلغ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'کد تراکنش',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () {}, child: const Text('پرداخت با موجودی کیف پول')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () {}, child: const Text('پرداخت با رمز ارز ملی')),
              const SizedBox(height: 16),
              Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('وضعیت اتصال ایمن'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
