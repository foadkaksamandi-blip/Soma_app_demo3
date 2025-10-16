import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'nearby_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const buyerId = 'buyer-109006'; // در صورت نیاز خودت تغییر بده
  await NearbyService.I.init(role: PeerRole.buyer, localUserName: buyerId);
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ خریدار سوما',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const BuyerHome(),
    );
  }
}

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  int balance = 800000; // تومان (دمو)
  int? pendingAmount;
  String? sellerId;
  bool discovering = false;
  bool paid = false;

  @override
  void initState() {
    super.initState();

    NearbyService.I.messages.listen((msg) {
      if (!mounted) return;
      if (msg.type == 'payment_receipt') {
        final amount = (msg.data['amount'] as num).toInt();
        setState(() {
          balance -= amount;
          paid = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('پرداخت ${amount.toString()} تومان انجام شد.')),
        );
      }
    });
  }

  @override
  void dispose() {
    NearbyService.I.stopAll();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
    if (result == null) return;
    setState(() {
      sellerId = result['seller'] as String?;
      pendingAmount = (result['amount'] as num?)?.toInt();
      paid = false;
    });
  }

  Future<void> _toggleDiscovery() async {
    if (discovering) {
      await NearbyService.I.stopAll();
      setState(() => discovering = false);
    } else {
      await NearbyService.I.startDiscovery();
      setState(() => discovering = true);
    }
  }

  Future<void> _pay() async {
    if (pendingAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا QR فروشنده را اسکن کنید')),
      );
      return;
    }
    final ok = await NearbyService.I
        .sendMessage(SomaMessage('payment_request', {'amount': pendingAmount}));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اتصال برقرار نیست. ابتدا اتصال بلوتوث را فعال کنید.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = <Widget>[];
    if (sellerId != null) {
      info.add(Text('فروشنده: $sellerId'));
    }
    if (pendingAmount != null) {
      info.add(Text('مبلغ در انتظار پرداخت: ${pendingAmount.toString()} تومان'));
    }
    if (paid) {
      info.add(const Text('✅ پرداخت تایید شد'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('خریدار')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: Colors.blue.withOpacity(.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('موجودی فعلی: ${balance.toString()} تومان',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _scanQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('اسکن QR فروشنده'),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('اتصال بلوتوث (Nearby) به فروشنده'),
            subtitle: Text(discovering ? 'در حال جست‌وجو…' : 'غیرفعال'),
            trailing: Switch(
              value: discovering,
              onChanged: (_) => _toggleDiscovery(),
            ),
          ),
          const SizedBox(height: 8),
          if (info.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: info),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _pay,
            child: const Text('پرداخت'),
          ),
        ],
      ),
    );
  }
}

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    final raw = cap.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['amount'] != null && m['seller'] != null) {
        _handled = true;
        Navigator.of(context).pop(m);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن QR')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }
}
