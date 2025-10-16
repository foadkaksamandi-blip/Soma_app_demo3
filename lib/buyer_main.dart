import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// پنل BLE (در صورت اضافه‌کردن فایل‌ها نمایش می‌دهد؛ نبودش هم مشکلی ایجاد نمی‌کند)
import 'widgets/buyer_ble_panel.dart' show BuyerBlePanel;

void main() {
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ خریدار سوما',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A4FB3)),
        useMaterial3: true,
        fontFamily: 'sans-serif',
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
  int _balance = 800000;
  String? _scannedSellerId;
  int? _scannedAmount;

  Future<void> _scanSellerQr() async {
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScanPage(title: 'اسکن QR فروشنده')),
    );

    if (result == null) return;

    // فرمت انتظار: SELLER|amount=<A>|sellerId=<ID>
    final parts = result.split('|');
    if (parts.isEmpty || parts.first != 'SELLER') {
      _toast('کد فروشنده معتبر نیست');
      return;
    }

    String? sellerId;
    int? amount;
    for (final p in parts.skip(1)) {
      final kv = p.split('=');
      if (kv.length != 2) continue;
      if (kv[0] == 'sellerId') sellerId = kv[1];
      if (kv[0] == 'amount') amount = int.tryParse(kv[1]);
    }

    if (sellerId == null || amount == null) {
      _toast('کد ناقص است');
      return;
    }

    setState(() {
      _scannedSellerId = sellerId;
      _scannedAmount = amount;
    });
    _toast('فروشنده: $sellerId | مبلغ: $amount تومان');
  }

  void _pay() {
    if (_scannedSellerId == null || _scannedAmount == null) {
      _toast('ابتدا QR فروشنده را اسکن کنید');
      return;
    }
    final amt = _scannedAmount!;
    if (amt <= 0) {
      _toast('مبلغ نامعتبر است');
      return;
    }
    if (_balance < amt) {
      _toast('موجودی کافی نیست');
      return;
    }

    setState(() => _balance -= amt);

    // تولید رسید پرداخت برای اسکن فروشنده
    final receipt = 'RECEIPT|sellerId=${_scannedSellerId!}|amount=$amt';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ReceiptPage(receipt: receipt),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final moneyStyle = TextStyle(
      color: Colors.green.shade700,
      fontWeight: FontWeight.w700,
      fontSize: 32,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('اپ خریدار سوما')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(label: 'موجودی فعلی', amount: _balance),
          const SizedBox(height: 16),

          // دکمه اسکن فروشنده
          ElevatedButton.icon(
            onPressed: _scanSellerQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('اسکن QR فروشنده'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 12),

          // دکمه پرداخت
          ElevatedButton(
            onPressed: _pay,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('پرداخت'),
          ),

          const SizedBox(height: 8),
          if (_scannedSellerId != null && _scannedAmount != null)
            Text(
              'آماده پرداخت به فروشنده: $_scannedSellerId با مبلغ ${_scannedAmount!} تومان',
              style: const TextStyle(fontSize: 14),
            ),

          // پنل BLE (اختیاری)
          const SizedBox(height: 20),
          const BuyerBlePanel(onPick: null),
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

class _ReceiptPage extends StatelessWidget {
  final String receipt;
  const _ReceiptPage({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رسید پرداخت')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(data: receipt, size: 260),
            const SizedBox(height: 12),
            const Text('این QR را به فروشنده نشان دهید'),
          ],
        ),
      ),
    );
  }
}
