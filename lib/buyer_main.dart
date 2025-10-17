// lib/buyer_main.dart
import 'package:flutter/material.dart';
import 'services/ble_permissions.dart';
import 'services/ble_service.dart';

void main() {
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
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
  final BleService _ble = BleService();
  int _balance = 800000;
  String _lastPayload = '—';

  Future<void> _scan() async {
    final ok = await BlePermissions.ensureBlePermissions();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اجازه‌های بلوتوث داده نشد')),
        );
      }
      return;
    }

    setState(() => _lastPayload = 'در حال اسکن...');
    await for (final p in _ble.scanForSeller()) {
      setState(() => _lastPayload = p);
      // اینجا می‌تونی منطق پرداخت/QR یا افزایش موجودی را وصل کنی
      break;
    }
    if (mounted && _lastPayload == 'در حال اسکن...') {
      setState(() => _lastPayload = 'چیزی پیدا نشد');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اپ خریدار سوما')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('موجودی فعلی: $_balance تومان',
                    style: const TextStyle(fontSize: 22, color: Colors.green)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _scan,
              child: const Text('اسکن فروشنده (BLE)'),
            ),
            const SizedBox(height: 12),
            Text('آخرین پیام BLE: $_lastPayload'),
            const SizedBox(height: 16),
            const Divider(),
            const Text('QR مرجع شما بدون تغییر باقی مانده است.'),
          ],
        ),
      ),
    );
  }
}
