import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'models/ble_message.dart';
import 'services/ble_service.dart';
import 'receipt.dart';

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  int _balance = 800000; // تومان
  String buyerId = 'buyer-${Random().nextInt(900000) + 100000}';

  // داده‌ی درخواست پرداخت اسکن‌شده از فروشنده
  String? _scannedSellerId;
  int? _scannedAmount;

  // رسید پس از پرداخت (برای نمایش QR به فروشنده)
  String? _receiptQr;

  // BLE
  final BleService _ble = BleService();
  bool _bleScanning = false;
  bool _bleAdvertisingReceipt = false;

  @override
  void dispose() {
    _ble.stopScan();
    _ble.stopAdvertising();
    super.dispose();
  }

  Future<void> _scanSellerQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScanPage(title: 'اسکن QR فروشنده')),
    );
    if (code == null) return;
    final ok = code.startsWith('type=SELLER|');
    if (!ok) return;

    final amtStr = RegExp(r'amount=(\d+)').firstMatch(code)?.group(1);
    final sid = RegExp(r'sellerId=([^\|]+)').firstMatch(code)?.group(1);
    if (amtStr != null && sid != null) {
      setState(() {
        _scannedAmount = int.tryParse(amtStr) ?? 0;
        _scannedSellerId = sid;
      });
    }
  }

  void _pay() {
    if (_scannedAmount == null || _scannedSellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا کد فروشنده را اسکن کنید')),
      );
      return;
    }
    final amt = _scannedAmount!;
    if (amt <= 0 || _balance < amt) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موجودی کافی نیست')),
      );
      return;
    }
    setState(() {
      _balance -= amt;
      // ساخت رسید برای فروشنده (QR)
      _receiptQr = 'type=RECEIPT|amount=$amt|sellerId=$_scannedSellerId|buyerId=$buyerId';
    });

    // نمایش صفحه رسید
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(qrData: _receiptQr!, title: 'رسید پرداخت'),
      ),
    );
  }

  // ---- BLE دمو ----
  Future<void> _scanSellerByBLE() async {
    await _ble.stopAdvertising();
    await _ble.stopScan();

    setState(() {
      _bleScanning = true;
      _scannedSellerId = null;
      _scannedAmount = null;
    });

    await _ble.startScan(onMessage: (msg) {
      if (msg.type == BleMsgType.payRequest) {
        setState(() {
          _scannedSellerId = msg.partyId;
          _scannedAmount = msg.amount;
          _bleScanning = false;
        });
        _ble.stopScan();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('درخواست فروشنده پیدا شد: ${msg.amount} تومان')),
        );
      }
    });
  }

  Future<void> _advertiseReceiptBLE() async {
    if (_scannedSellerId == null || _scannedAmount == null) return;
    final msg = BleMessage(
      type: BleMsgType.payReceipt,
      partyId: buyerId,
      amount: _scannedAmount!,
      note: 'to=$_scannedSellerId',
    );
    await _ble.startAdvertising(msg);
    setState(() => _bleAdvertisingReceipt = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('در حال پخش رسید با بلوتوث...')),
    );
  }

  Future<void> _stopAllBle() async {
    await _ble.stopScan();
    await _ble.stopAdvertising();
    setState(() {
      _bleScanning = false;
      _bleAdvertisingReceipt = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPay = _scannedSellerId != null && _scannedAmount != null;

    return Scaffold(
      appBar: AppBar(title: const Text('اپ خریدار سوما')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(title: 'موجودی فعلی', amount: _balance),

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _scanSellerQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('اسکن QR فروشنده'),
          ),
          const SizedBox(height: 8),
          if (_scannedAmount != null && _scannedSellerId != null)
            Text(
              'داده‌ی اسکن شده: amount=${_scannedAmount}, sellerId=$_scannedSellerId',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canPay ? _pay : null,
            child: const Text('پرداخت'),
          ),

          const Divider(height: 32),
          Text('بلوتوث (آزمایشی)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _bleScanning ? _stopAllBle : _scanSellerByBLE,
            child: Text(_bleScanning ? 'توقف اسکن بلوتوث' : 'یافتن فروشنده با بلوتوث'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _bleAdvertisingReceipt ? _stopAllBle : _advertiseReceiptBLE,
            child: Text(_bleAdvertisingReceipt ? 'توقف پخش رسید' : 'ارسال رسید با بلوتوث'),
          ),
          const SizedBox(height: 12),

          if (_receiptQr != null) ...[
            const SizedBox(height: 24),
            Center(
              child: QrImageView(
                data: _receiptQr!,
                size: 260,
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('این QR را به فروشنده نشان دهید')),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final int amount;
  const _BalanceCard({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${amount} تومان',
              style: theme.textTheme.displaySmall?.copyWith(color: Colors.green.shade700)),
        ],
      ),
    );
  }
}

class _QrScanPage extends StatelessWidget {
  final String title;
  const _QrScanPage({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) Navigator.of(context).pop(code);
        },
      ),
    );
  }
}
