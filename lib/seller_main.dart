import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SellerApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  int balance = 500000;
  int lastPayment = 0;

  String createPaymentQr(int amount) {
    final id = const Uuid().v4();
    final payload = {
      "type": "payment",
      "id": id,
      "amount": amount,
      "currency": "IRR",
      "ts": DateTime.now().toIso8601String(),
    };
    return payload.toString();
  }

  void applyPayment(int amount) {
    lastPayment = amount;
    balance = (balance - amount).clamp(0, 1 << 31);
    notifyListeners();
  }
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soma Seller Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
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
  final _amountCtrl = TextEditingController(text: '75000');
  String? _qrData;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('فروشنده (دمو)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('موجودی کیف پول (ریال)'),
              subtitle: Text(app.balance.toString()),
              trailing: app.lastPayment > 0
                  ? Text('آخرین پرداخت: ${app.lastPayment}')
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مبلغ پرداخت (ریال)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.qr_code),
            label: const Text('تولید QR واقعی برای پرداخت'),
            onPressed: () {
              final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
              setState(() => _qrData = app.createPaymentQr(amount));
            },
          ),
          const SizedBox(height: 20),
          if (_qrData != null) ...[
            Center(
              child: QrImageView(
                data: _qrData!,
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text('Payload:', style: Theme.of(context).textTheme.titleMedium),
            SelectableText(_qrData!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
                context.read<AppState>().applyPayment(amount);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('پرداخت ${amount} ریال ثبت شد')),
                );
              },
              child: const Text('اعمال پرداخت (دمو)'),
            ),
          ],
        ],
      ),
    );
  }
}
