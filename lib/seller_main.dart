import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => AppState(),
    child: const SellerApp(),
  ));
}

class AppState extends ChangeNotifier {
  int balance = 500000; // موجودی اولیه (ریال)
  String lastTransaction = "ندارد";

  void updateBalance(int amount) {
    balance -= amount;
    notifyListeners();
  }

  void recordTransaction(String id) {
    lastTransaction = id;
    notifyListeners();
  }
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ فروشنده سوما',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SellerHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  final TextEditingController amountController = TextEditingController();
  String qrData = "";

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('فروشنده — تراکنش آفلاین'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('موجودی فعلی: ${state.balance} ریال',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ خرید (ریال)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                final amount = int.tryParse(amountController.text) ?? 0;
                if (amount > 0 && amount <= state.balance) {
                  final uuid = const Uuid().v4();
                  final newQr = "$uuid|$amount";
                  setState(() {
                    qrData = newQr;
                  });
                  state.updateBalance(amount);
                  state.recordTransaction(uuid);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("مبلغ نامعتبر یا بیش از موجودی است"),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('تولید QR کد'),
            ),
            const SizedBox(height: 30),
            if (qrData.isNotEmpty)
              Center(
                child: QrImage(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            const SizedBox(height: 30),
            Text('آخرین تراکنش: ${state.lastTransaction}'),
          ],
        ),
      ),
    );
  }
}
