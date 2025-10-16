import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'nearby_service.dart';

void main() {
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SellerPage(),
    );
  }
}

class SellerPage extends StatefulWidget {
  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final NearbyService nearbyService = NearbyService();
  String sellerId = const Uuid().v4();
  int currentBalance = 500000;
  int newAmount = 0;

  @override
  void initState() {
    super.initState();
    nearbyService.startAdvertising('Seller_$sellerId', _onReceive);
  }

  void _onReceive(String endpointId, String message) {
    try {
      int received = int.parse(message);
      setState(() {
        currentBalance += received;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💰 مبلغ $received تومان دریافت شد!')),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    nearbyService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("اپ فروشنده سوما")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("موجودی فعلی: $currentBalance تومان",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: "مبلغ جدید (تومان)"),
              keyboardType: TextInputType.number,
              onChanged: (value) => newAmount = int.tryParse(value) ?? 0,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text("اعمال مبلغ جدید"),
            ),
            const SizedBox(height: 20),
            Text("کد فروشنده: $sellerId"),
            const SizedBox(height: 20),
            QrImageView(
              data: newAmount.toString(),
              version: QrVersions.auto,
              size: 200.0,
            ),
          ],
        ),
      ),
    );
  }
}
