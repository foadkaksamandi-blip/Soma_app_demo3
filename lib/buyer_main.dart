import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ خریدار سوما',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
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
  int balance = 800000; // ✅ بدون جداکننده
  int transactionAmount = 0;
  String qrData = '';

  void generateQR() {
    setState(() {
      var uuid = const Uuid();
      qrData =
          'TXN:${uuid.v4()}|AMOUNT:$transactionAmount|BALANCE:${balance - transactionAmount}';
    });
  }

  void handleTransaction() {
    if (transactionAmount <= 0) return;
    if (transactionAmount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موجودی کافی نیست')),
      );
      return;
    }
    setState(() {
      balance -= transactionAmount;
      transactionAmount = 0;
      qrData = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('اپ خریدار سوما'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'موجودی فعلی',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$balance تومان',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ خرید (تومان)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                transactionAmount = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: generateQR,
              icon: const Icon(Icons.qr_code),
              label: const Text('تولید QR برای پرداخت'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            if (qrData.isNotEmpty)
              Center(
                child: Column(
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'کد QR پرداخت آماده است',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: handleTransaction,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('تایید تراکنش آفلاین'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
