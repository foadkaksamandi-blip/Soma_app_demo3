import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SellerApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  final String sellerId = const Uuid().v4();
  int amount = 500000; // تومان

  void setAmount(int v) {
    amount = v;
    notifyListeners();
  }

  void plus(int v) {
    amount += v;
    notifyListeners();
  }

  void minus(int v) {
    amount = (amount - v).clamp(0, 1 << 31);
    notifyListeners();
  }
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seller',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const SellerHome(),
    );
  }
}

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final qrData = {
      'sellerId': app.sellerId,
      'amount': app.amount,
      'currency': 'IRR',
      'ts': DateTime.now().toIso8601String(),
    }.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Seller')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                gapless: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'مبلغ فعلی: ${app.amount} تومان',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ جدید (تومان)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final v = int.tryParse(_controller.text.trim());
                    if (v != null) {
                      context.read<AppState>().setAmount(v);
                      _controller.clear();
                    }
                  },
                  child: const Text('اعمال'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<AppState>().minus(10000),
                    child: const Text('- 10,000'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<AppState>().plus(10000),
                    child: const Text('+ 10,000'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  'Seller ID: ${app.sellerId}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
