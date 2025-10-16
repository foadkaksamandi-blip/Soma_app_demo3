import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// پنل BLE (در صورت موجود بودن فایل‌ها)
import 'widgets/seller_ble_panel.dart' show SellerBlePanel;

void main() {
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ فروشنده سوما',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A4FB3)),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      home: const SellerHomePage(),
    );
  }
}

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  final String sellerId = 'seller-210441';
  int _balance = 600000;

  final TextEditingController _amountCtrl = TextEditingController(text: '100000');
  String? _payQrData; // داده QR فروش

  String _buildSellerQr(int amount) =>
      'SELLER|amount=$amount|sellerId=$sellerId';

  void _generateQr() {
    final amt = int.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;
    if (amt <= 0) {
      _toast('مبلغ نامعتبر است');
      return;
    }
    setState(() => _payQrData = _buildSellerQr(amt));
  }

  Future<void> _scanBuyerReceipt() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScanPage(title: 'اسکن رسید خریدار')),
    );
    if (result == null) return;

    // فرمت انتظار: RECEIPT|sellerId=<ID>|amount=<A>
    final parts = result.split('|');
    if (parts.isEmpty || parts.first != 'RECEIPT') {
      _toast('رسید نامعتبر است');
      return;
    }
    String? rSellerId;
    int? rAmount;
    for (final p in parts.skip(1)) {
      final kv = p.split('=');
      if (kv.length != 2) continue;
      if (kv[0] == 'sellerId') rSellerId = kv[1];
      if (kv[0] == 'amount') rAmount = int.tryParse(kv[1]);
    }
    if (rSellerId != sellerId || rAmount == null || rAmount <= 0) {
      _toast('رسید نامعتبر است');
      return;
    }

    setState(() {
      _balance += rAmount!;
    });
    _toast('واریز شد: $rAmount تومان');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فروشنده')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(label: 'مبلغ فعلی', amount: _balance),
          const SizedBox(height: 16),

          // ورودی مبلغ
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'مبلغ جدید (تومان)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // تولید QR فروش
          ElevatedButton(
            onPressed: _generateQr,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('تولید QR برای پرداخت'),
          ),

          const SizedBox(height: 16),
          if (_payQrData != null) ...[
            Center(child: QrImageView(data: _payQrData!, size: 240)),
            const SizedBox(height: 8),
            const Center(child: Text('این QR را به خریدار نشان دهید')),
          ],

          const SizedBox(height: 20),

          // اسکن رسید خریدار
          ElevatedButton.icon(
            onPressed: _scanBuyerReceipt,
            icon: const Icon(Icons.receipt_long),
            label: const Text('اسکن رسید خریدار'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),

          // پنل BLE فروشنده (اختیاری)
          const SizedBox(height: 20),
          SellerBlePanel(sellerId: sellerId),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final int amount;
  const _BalanceCard({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label :', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '$amount تومان',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrScanPage extends StatefulWidget {
  final String title;
  const _QrScanPage({required this.title});

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final codes = capture.barcodes;
          if (codes.isNotEmpty) {
            final raw = codes.first.rawValue;
            Navigator.pop(context, raw);
          }
        },
      ),
    );
  }
}
