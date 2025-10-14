import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'common.dart';

const _bleChannel = MethodChannel('com.soma.app/ble');

void main() {
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const SellerApp()));
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'SOMA Seller', theme: sellerTheme(), home: const SellerHome());
  }
}

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});
  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  final amtCtrl = TextEditingController();
  String txId = '';
  bool advertising = false;

  @override
  void dispose() {
    amtCtrl.dispose();
    super.dispose();
  }

  void genQr() {
    final st = context.read<AppState>();
    txId = st.genTxId();
    final amount = double.tryParse(amtCtrl.text.trim()) ?? 0;
    st.newTx(txId: txId, amount: amount);
    setState(() {});
  }

  Future<void> toggleBleServer() async {
    if (!advertising) {
      final ok = await _bleChannel.invokeMethod<bool>('startServer') ?? false;
      setState(() => advertising = ok);
      if (!ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مشکل در شروع BLE Server')));
    } else {
      await _bleChannel.invokeMethod('stopServer');
      setState(() => advertising = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final qrData = jsonEncode({'txId': txId, 'amount': st.lastAmount, 'ts': DateTime.now().millisecondsSinceEpoch});
    final statusColor = st.status == 'موفق' ? Colors.green : (st.status == 'ناموفق' ? Colors.red : Colors.orange);

    return Scaffold(
      appBar: AppBar(title: const Text('اپ آفلاین سوما')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('اپ فروشنده', textAlign: TextAlign.right, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'مبلغ فروش', border: OutlineInputBorder()), keyboardType: TextInputType.number, textAlign: TextAlign.right),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: genQr, child: const Text('تولید QR برای دریافت مبلغ')),
          const SizedBox(height: 12),
          if (txId.isNotEmpty) Center(child: QrImage(data: qrData, size: 220)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: toggleBleServer,
            icon: Icon(advertising ? Icons.stop : Icons.bluetooth_audio),
            label: Text(advertising ? 'توقف BLE Server' : 'اتصال امن با بلوتوث (تبلیغ)'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('وضعیت: ${st.status}'),
              Text('txId: ${st.lastTxId}'),
              Text('amount: ${st.lastAmount.toStringAsFixed(0)}'),
              Text('BLE Server: ${advertising ? 'فعال' : 'غیرفعال'}'),
            ]),
          ),
        ],
      ),
    );
  }
}
