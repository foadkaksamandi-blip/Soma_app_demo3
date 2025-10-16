import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'nearby_service.dart';

void main() {
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BuyerPage(),
    );
  }
}

class BuyerPage extends StatefulWidget {
  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  final NearbyService nearbyService = NearbyService();
  int balance = 800000;
  String? scannedAmount;
  String? connectedId;

  @override
  void initState() {
    super.initState();
    nearbyService.startDiscovery('Buyer_Device', (id, msg) {});
  }

  void _onScan(String code) {
    setState(() => scannedAmount = code);
  }

  void _confirmPayment() {
    if (scannedAmount == null || connectedId == null) return;
    int amount = int.tryParse(scannedAmount!) ?? 0;
    if (amount <= 0 || amount > balance) return;

    nearbyService.sendData(connectedId!, scannedAmount!);
    setState(() => balance -= amount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ پرداخت $amount تومان انجام شد.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("اپ خریدار سوما")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("موجودی فعلی: $balance تومان",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("اسکن QR فروشنده"),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QRScanner(onScan: _onScan),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            if (scannedAmount != null)
              ElevatedButton(
                onPressed: _confirmPayment,
                child: const Text("تأیید تراکنش آفلاین"),
              ),
          ],
        ),
      ),
    );
  }
}

class QRScanner extends StatelessWidget {
  final Function(String) onScan;
  const QRScanner({required this.onScan, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("اسکن QR فروشنده")),
      body: MobileScanner(
        onDetect: (barcode) {
          if (barcode.rawValue != null) {
            onScan(barcode.rawValue!);
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
