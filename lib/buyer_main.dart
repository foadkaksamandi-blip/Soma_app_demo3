import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DemoStore.instance.load();
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
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
  final _amountCtrl = TextEditingController();
  final _txnCtrl = TextEditingController();
  final _scanner = BleScanner();
  String _status = 'waiting'; // waiting | ok | error
  String _statusText = 'در انتظار…';
  List<ScanResult> _scan = [];

  void _setStatus(String mode, String text) {
    setState(() {
      _status = mode;
      _statusText = text;
    });
  }

  Future<void> _scanBle() async {
    try {
      _setStatus('waiting', 'در حال اسکن دستگاه‌ها…');
      final res = await _scanner.scanOnce();
      setState(() => _scan = res);
      if (res.isEmpty) {
        _setStatus('error', 'دستگاهی پیدا نشد.');
      } else {
        _setStatus('ok', 'اسکن موفق — یک فروشنده انتخاب کنید (دمو).');
      }
    } catch (e) {
      _setStatus('error', e.toString());
    }
  }

  Future<void> _mockPay() async {
    final amt = int.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      _setStatus('error', 'مبلغ نامعتبر است.');
      return;
    }
    if (DemoStore.instance.buyerBalance < amt) {
      _setStatus('error', 'موجودی کافی نیست.');
      return;
    }
    // دمو: تراکنش محلی با تولید TxnID
    final now = DateTime.now();
    final txnId = 'SOMA-${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}-${now.millisecondsSinceEpoch % 100000}';
    _txnCtrl.text = txnId;

    // بروزرسانی موجودی‌ها (سمت خریدار)
    DemoStore.instance.buyerBalance -= amt;
    await DemoStore.instance.addHistory(Txn('buyer', amt, txnId, now.millisecondsSinceEpoch));
    await DemoStore.instance.save();

    _setStatus('ok', 'پرداخت موفق — کد تراکنش: $txnId');
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
            Text('اپ خریدار', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // موجودی
            Card(
              child: ListTile(
                title: const Text('موجودی خریدار'),
                trailing: Text(formatTomans(store.buyerBalance)),
              ),
            ),

            const SizedBox(height: 12),
            Text('انتخاب نوع اتصال یا پرداخت'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanBle,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('اتصال با بلوتوث'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _setStatus('waiting', 'حالت QR (دمو) — آماده اسکن');
                    },
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('اسکن QR کد'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text('مبلغ خرید'),
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
            Text('کد تراکنش'),
            const SizedBox(height: 6),
            TextField(
              controller: _txnCtrl,
              decoration: const InputDecoration(
                hintText: 'کد پس از پرداخت پر می‌شود یا دستی وارد کنید',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            statusCard,

            const SizedBox(height: 12),
            // دکمه‌های پایینی نمایشی
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _mockPay,
                    child: const Text('پرداخت با موجودی کیف پول'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _setStatus('ok', 'پرداخت (نمایشی) با رمز ارز ملی انجام شد'),
                    child: const Text('پرداخت با رمز ارز ملی'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _setStatus('waiting', 'در انتظار…'),
              child: const Text('لغو / پاکسازی وضعیت'),
            ),

            if (_scan.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('نتایج اسکن (نمایشی):', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              ..._scan.map((r) => ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(r.device.platformName.isNotEmpty ? r.device.platformName : '(بدون‌نام)'),
                    subtitle: Text(r.device.remoteId.str),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
