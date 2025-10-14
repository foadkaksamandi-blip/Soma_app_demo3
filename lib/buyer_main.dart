import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'common.dart';
import 'ble_client.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const BuyerApp()));
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SOMA Buyer', theme: buyerTheme(), home: const BuyerHome());
  }
}

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});
  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  final amountCtrl = TextEditingController();
  final txCtrl = TextEditingController();
  final client = SomaBleClient();

  @override
  void dispose() {
    amountCtrl.dispose();
    txCtrl.dispose();
    client.disconnect();
    super.dispose();
  }

  Future<void> scanQr() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
    if (res is Map<String, dynamic>) {
      final st = context.read<AppState>();
      final amt = double.tryParse(res['amount']?.toString() ?? '0') ?? 0;
      final tx = (res['txId'] ?? '').toString();
      amountCtrl.text = amt.toStringAsFixed(0);
      txCtrl.text = tx;
      st.newTx(txId: tx, amount: amt);
    }
  }

  Future<void> connectBle() async {
    final ok = await client.connect();
    context.read<AppState>().setConnection(ok, name: client.device?.platformName ?? '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'اتصال BLE برقرار شد' : 'اتصال برقرار نشد')));
  }

  Future<void> sendOverBle() async {
    final st = context.read<AppState>();
    final txId = txCtrl.text.trim();
    final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (txId.isEmpty || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مبلغ/کد تراکنش معتبر نیست')));
      return;
    }
    final ok = await client.sendJson({'txId': txId, 'amount': amt, 'ts': DateTime.now().millisecondsSinceEpoch});
    st.setStatus(ok ? 'موفق' : 'ناموفق');
    if (ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ارسال تراکنش از طریق BLE')));
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final statusColor = st.status == 'موفق' ? Colors.green : (st.status == 'ناموفق' ? Colors.red : Colors.orange);
    return Scaffold(
      appBar: AppBar(title: const Text('اپ آفلاین سوما')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('اپ خریدار', textAlign: TextAlign.right, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('موجودی خریدار: 1,000,000 ریال', textAlign: TextAlign.right),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: scanQr, icon: const Icon(Icons.qr_code_scanner), label: const Text('اسکن QR کد'))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(onPressed: connectBle, icon: const Icon(Icons.bluetooth), label: const Text('اتصال بلوتوث'))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'مبلغ خریدار', border: OutlineInputBorder()), keyboardType: TextInputType.number, textAlign: TextAlign.right),
          const SizedBox(height: 12),
          TextField(controller: txCtrl, decoration: const InputDecoration(labelText: 'کد تراکنش', border: OutlineInputBorder()), textAlign: TextAlign.right),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: () => context.read<AppState>().setStatus('موفق'), icon: const Icon(Icons.account_balance_wallet), label: const Text('پرداخت با کیف پول'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(onPressed: () => context.read<AppState>().setStatus('موفق'), icon: const Icon(Icons.currency_exchange), label: const Text('پرداخت با رمز ارز ملی'))),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: sendOverBle, child: const Text('ارسال از طریق BLE')),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('وضعیت: ${st.status}'),
              Text('اتصال BLE: ${st.bleConnected ? 'ایمن (${st.connectedDevice})' : 'برقرار نیست'}'),
              Text('txId: ${st.lastTxId}'),
              Text('amount: ${st.lastAmount.toStringAsFixed(0)}'),
            ]),
          ),
        ],
      ),
    );
  }
}

class _QrScanPage extends StatelessWidget {
  const _QrScanPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
          if (code != null) {
            try {
              final map = jsonDecode(code) as Map<String, dynamic>;
              Navigator.pop(context, map);
            } catch (_) {
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }
}
