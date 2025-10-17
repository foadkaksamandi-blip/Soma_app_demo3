import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'services/ble_service.dart';

void main() => runApp(const BuyerApp());

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BuyerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BuyerScreen extends StatefulWidget {
  const BuyerScreen({super.key});
  @override
  State<BuyerScreen> createState() => _BuyerScreenState();
}

class _BuyerScreenState extends State<BuyerScreen> {
  final ble = BleService();
  bool _scanning = false;
  List<ScanResult> _items = const [];

  @override
  void initState() {
    super.initState();
    ble.scanResults.listen((r) {
      setState(() => _items = r);
    });
  }

  @override
  void dispose() {
    ble.stopScan();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_scanning) {
      await ble.stopScan();
    } else {
      await ble.startScan(timeout: const Duration(seconds: 10));
    }
    setState(() => _scanning = !_scanning);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buyer Mode (Scanner)')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _toggle,
            child: Text(_scanning ? 'Stop Scan' : 'Start Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final r = _items[i];
                return ListTile(
                  title: Text(r.device.platformName.isEmpty
                      ? r.device.remoteId.str
                      : r.device.platformName),
                  subtitle: Text('RSSI: ${r.rssi}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
