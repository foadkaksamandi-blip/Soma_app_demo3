import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'models/ble_message.dart';
import 'services/ble_service.dart';
import 'receipt.dart';

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  int _balance = 500000; // تومان
  final _amountCtrl = TextEditingController();
  String sellerId = 'seller-${Random().nextInt(900000) + 100000}';

  // QR داده پرداخت
  String? _payQrText;

  // BLE
  final BleService _ble = BleService();
  bool _bleAdvertising = false;
  String _receiptScanStatus = 'رسید نامعتبر است';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _ble.stopAdvertising();
    super.dispose();
  }

  void _makePayRequest() {
    final amt = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ معتبر وارد کنید')),
      );
      return;
    }
    // QR پرداخت (درخواست از فروشنده)
    _payQrText = 'type=SELLER|amount=$amt|sellerId=$sellerId';
    setState(() {});
  }

  Future<void> _scanBuyerReceipt() async {
    // اسکن QR رسید خریدار
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScanPage(title: 'اسکن رسید خریدار')),
    );
    if (code == null) return;
    final ok = code.startsWith('type=RECEIPT|') && code.contains('sellerId=$sellerId|');
    if (ok) {
      final amtStr = RegExp(r'amount=(\d+)').firstMatch(code)?.group(1);
      final amt = int.tryParse(amtStr ?? '0') ?? 0;
      if (amt > 0) {
        setState(() {
          _balance += amt;
          _receiptScanStatus = 'رسید معتبر ✔️ واریز شد';
        });
      }
    } else {
      setState(() => _receiptScanStatus = 'رسید نامعتبر است');
    }
  }

  // ---- BLE (آزمایشی) ----
  Future<void> _advertisePayRequestBLE() async {
    final amt = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ معتبر وارد کنید')),
      );
      return;
    }
    final msg = BleMessage(
      type: BleMsgType.payRequest,
      partyId: sellerId,
      amount: amt,
      note: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await _ble.startAdvertising(msg);
    setState(() => _bleAdvertising = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('در حال پخش درخواست پرداخت با بلوتوث...')),
    );
  }

  Future<void> _stopAdvertise() async {
    await _ble.stopAdvertising();
    setState(() => _bleAdvertising = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('فروشنده')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(title: 'مبلغ فعلی', amount: _balance),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'مبلغ جدید (تومان)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _makePayRequest,
            child: const Text('تولید QR برای پرداخت'),
          ),
          const SizedBox(height: 12),

          // --- BLE controls ---
          FilledButton.tonal(
            onPressed: _bleAdvertising ? _stopAdvertise : _advertisePayRequestBLE,
            child: Text(_bleAdvertising ? 'توقف پخش بلوتوث' : 'ارسال با بلوتوث (آزمایشی)'),
          ),
          const SizedBox(height: 20),

          if (_payQrText != null) ...[
            Center(
              child: QrImageView(
                data: _payQrText!,
                size: 280,
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('این QR را به خریدار نشان دهید')),
          ],

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _scanBuyerReceipt,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('اسکن رسید خریدار'),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _receiptScanStatus,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}

/// کارت نمایش موجودی
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
          Text('$title :', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${amount} تومان',
              style: theme.textTheme.displaySmall?.copyWith(color: Colors.green.shade700)),
        ],
      ),
    );
  }
}

/// اسکنر QR ساده
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
          if (code != null) {
            Navigator.of(context).pop(code);
          }
        },
      ),
    );
  }
}
