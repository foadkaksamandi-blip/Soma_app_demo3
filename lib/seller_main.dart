import 'package:flutter/material.dart';
import 'common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DemoStore.instance.load();
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF8E24AA)); // بنفش
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
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
  final _amountCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _status = 'waiting';
  String _statusText = 'در انتظار…';

  void _setStatus(String mode, String text) {
    setState(() {
      _status = mode;
      _statusText = text;
    });
  }

  Future<void> _readyBluetooth() async {
    final ok = await ensureBlePermissions();
    if (!ok) {
      _setStatus('error', 'مجوز بلوتوث لازم است.');
      return;
    }
    _setStatus('waiting', 'در انتظار اتصال خریدار (دمو)…');
  }

  Future<void> _generateQr() async {
    _setStatus('waiting', 'QR تولید شد (نمایشی). خریدار اسکن می‌کند…');
  }

  Future<void> _confirmReceive() async {
    final amt = int.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      _setStatus('error', 'مبلغ معتبر نیست.');
      return;
    }
    // دمو: موفقیت و ساخت کد تأیید
    final now = DateTime.now();
    final txnId = 'SOMA-${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}-${now.millisecondsSinceEpoch % 100000}';
    _confirmCtrl.text = txnId;

    // افزایش موجودی فروشنده (سمت خودش)
    DemoStore.instance.sellerBalance += amt;
    await DemoStore.instance.addHistory(Txn('seller', amt, txnId, now.millisecondsSinceEpoch));
    await DemoStore.instance.save();

    _setStatus('ok', 'مبلغ دریافت شد — کد تأیید: $txnId');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoStore.instance;

    Widget statusCard;
    if (_status == 'ok') {
      statusCard = StatusCard.ok(_statusText);
    } else if (_status == 'error') {
      statusCard = StatusCard.error(_statusText);
    } else {
      statusCard = const StatusCard.waiting();
    }

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('اپ آفلاین سوما')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('اپ فروشنده', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                title: const Text('موجودی فروشنده'),
                trailing: Text(formatTomans(store.sellerBalance)),
              ),
            ),

            const SizedBox(height: 12),
            Text('انتخاب روش دریافت'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _readyBluetooth,
                    icon: const Icon(Icons.bluetooth),
                    label: const Text('دریافت از بلوتوث'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generateQr,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('تولید QR کد'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text('مبلغ تراکنش'),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'مثلاً 150000',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            Text('کد تأیید تراکنش'),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: 'پس از دریافت موفق پر می‌شود',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            statusCard,

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _readyBluetooth,
                    child: const Text('آماده دریافت (بلوتوث)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _generateQr,
                    child: const Text('بازنشانی/تولید مجدد QR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _confirmReceive,
              child: const Text('تأیید دریافت وجه'),
            ),
          ],
        ),
      ),
    );
  }
}
