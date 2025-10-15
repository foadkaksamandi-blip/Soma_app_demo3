import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' show Random;

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SellerApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  String connection = 'قطع';
  int balance = 500_000; // موجودی فرضی فروشنده (ریال)
  int amount = 0;
  String txCode = '';

  void setAmount(int v) {
    amount = v;
    notifyListeners();
  }

  void genTx() {
    txCode = const Uuid().v4().split('-').first.toUpperCase();
    notifyListeners();
  }

  void toggleConnection() {
    connection = (connection == 'فعال') ? 'قطع' : 'فعال';
    notifyListeners();
  }

  void randomAmount() {
    amount = (Random().nextInt(50) + 1) * 10000;
    notifyListeners();
  }
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'آپ آفلاین سوما - فروشنده',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SellerHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SellerHome extends StatelessWidget {
  const SellerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final greenBox = BoxDecoration(
      color: s.connection == 'فعال' ? Colors.green.shade100 : Colors.red.shade100,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: s.connection == 'فعال' ? Colors.green : Colors.red,
        width: 1.5,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('آپ آفلاین سوما'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text('اپ فروشنده', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          // وضعیت اتصال امن
          Container(
            padding: const EdgeInsets.all(12),
            decoration: greenBox,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('اتصال امن:'),
                Text(s.connection, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // موجودی
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('موجودی فروشنده:'),
              Text('${s.balance} ریال', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          // مبلغ
          Row(
            children: [
              const Expanded(child: Text('مبلغ خرید (ریال):')),
              SizedBox(
                width: 160,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'مثلاً 120000',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => context.read<AppState>().setAmount(int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // تولید کد تراکنش و QR
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AppState>().genTx();
                  if (s.amount == 0) context.read<AppState>().randomAmount();
                },
                icon: const Icon(Icons.numbers),
                label: const Text('تولید کد تراکنش'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => context.read<AppState>().toggleConnection(),
                icon: const Icon(Icons.bluetooth),
                label: const Text('اتصال/قطع بلوتوث (نمایشی)'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (s.txCode.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('کد تراکنش: ${s.txCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Center(
                  child: QrImageView(
                    data: 'SOMA|SELL|AMT=${s.amount}|TX=${s.txCode}',
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
