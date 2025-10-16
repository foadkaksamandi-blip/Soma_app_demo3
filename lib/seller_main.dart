import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'nearby_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // یک شناسه ساده برای این فروشنده
  const sellerId = 'seller-210441'; // اگر خواستی از uuid بساز
  await NearbyService.I.init(role: PeerRole.seller, localUserName: sellerId);
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ فروشنده سوما',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
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
  int balance = 500000; // تومان (دمو)
  final _amountCtrl = TextEditingController();
  String sellerId = 'seller-210441';
  bool advertising = false;
  int? currentAmount; // مبلغی که QR برایش ساخته شده

  @override
  void initState() {
    super.initState();

    // دریافت پیام‌ها (از Buyer)
    NearbyService.I.messages.listen((msg) async {
      if (!mounted) return;
      if (msg.type == 'payment_request') {
        final amount = (msg.data['amount'] as num).toInt();
        setState(() => balance += amount);
        // رسید را برگردانیم
        await NearbyService.I
            .sendMessage(SomaMessage('payment_receipt', {'amount': amount}));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('پرداخت ${amount.toString()} تومان دریافت شد.')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    NearbyService.I.stopAll();
    super.dispose();
  }

  String _buildQrPayload(int amount) {
    final m = {'seller': sellerId, 'amount': amount};
    return jsonEncode(m);
  }

  Future<void> _toggleAdvertising() async {
    if (advertising) {
      await NearbyService.I.stopAll();
      setState(() => advertising = false);
    } else {
      await NearbyService.I.startAdvertising();
      setState(() => advertising = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = currentAmount != null ? _buildQrPayload(currentAmount!) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('فروشنده')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: Colors.green.withOpacity(.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('مبلغ فعلی: ${balance.toString()} تومان',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مبلغ جدید (تومان)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final v = int.tryParse(_amountCtrl.text.trim());
                    if (v == null || v <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('مبلغ معتبر وارد کنید')),
                      );
                      return;
                    }
                    setState(() => currentAmount = v);
                  },
                  child: const Text('تولید QR برای پرداخت'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (qrData != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 260,
                ),
                const SizedBox(height: 8),
                const Text('این QR را به خریدار نشان دهید'),
              ],
            ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('پخش بلوتوث (Nearby) برای اتصال خریدار'),
            subtitle: Text(advertising ? 'در حال پخش…' : 'غیرفعال'),
            trailing: Switch(
              value: advertising,
              onChanged: (_) => _toggleAdvertising(),
            ),
          ),
        ],
      ),
    );
  }
}
