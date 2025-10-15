import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BuyerState(),
      child: const BuyerApp(),
    ),
  );
}

class BuyerState extends ChangeNotifier {
  String connection = 'قطع';
  int balance = 800_000; // موجودی فرضی خریدار
  String paymentMethod = 'بلوتوث';
  String txCode = '';
  int amount = 0;

  void setMethod(String m) {
    paymentMethod = m;
    notifyListeners();
  }

  void setAmount(int v) {
    amount = v;
    notifyListeners();
  }

  void setTx(String t) {
    txCode = t;
    notifyListeners();
  }

  void toggleConnection() {
    connection = (connection == 'فعال') ? 'قطع' : 'فعال';
    notifyListeners();
  }
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'آپ آفلاین سوما - خریدار',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const BuyerHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BuyerHome extends StatelessWidget {
  const BuyerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<BuyerState>();
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
          Text('اپ خریدار', style: Theme.of(context).textTheme.titleLarge),
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
              const Text('موجودی خریدار:'),
              Text('${s.balance} ریال', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          // انتخاب روش پرداخت
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('انتخاب نوع اتصال/پرداخت:'),
              DropdownButton<String>(
                value: s.paymentMethod,
                items: const [
                  DropdownMenuItem(value: 'بلوتوث', child: Text('بلوتوث')),
                  DropdownMenuItem(value: 'QR', child: Text('QR')),
                ],
                onChanged: (v) => context.read<BuyerState>().setMethod(v ?? 'بلوتوث'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // دکمه‌ها
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.read<BuyerState>().toggleConnection(),
                  icon: const Icon(Icons.bluetooth),
                  label: const Text('اتصال با بلوتوث'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // نمایشی: در نسخه واقعی اینجا اسکن QR انجام می‌شود
                    context.read<BuyerState>().setTx('SCAN-MOCK');
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('اسکن QR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // مبلغ و کد تراکنش
          Row(
            children: [
              const Expanded(child: Text('مبلغ (ریال):')),
              SizedBox(
                width: 160,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'مثلاً 95000',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => context.read<BuyerState>().setAmount(int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Expanded(child: Text('کد تراکنش:')),
              SizedBox(
                width: 160,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'کد را وارد کنید',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => context.read<BuyerState>().setTx(v.trim()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // نمایش QR پرداخت از سمت خریدار (اختیاری/نمایشی)
          if (s.paymentMethod == 'QR' && s.amount > 0 && s.txCode.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اطلاعات پرداخت (QR)'),
                const SizedBox(height: 8),
                Center(
                  child: QrImageView(
                    data: 'SOMA|BUY|AMT=${s.amount}|TX=${s.txCode}',
                    size: 200,
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
