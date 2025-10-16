import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../services/ble_permissions.dart';

class BuyerBlePanel extends StatefulWidget {
  final void Function(String sellerId)? onPick;
  const BuyerBlePanel({super.key, this.onPick});

  @override
  State<BuyerBlePanel> createState() => _BuyerBlePanelState();
}

class _BuyerBlePanelState extends State<BuyerBlePanel> {
  final _ble = BleService();
  bool _scanning = false;
  final Map<String, ScanResult> _found = {};
  StreamSubscription<bool>? _scanStateSub;

  Future<void> _toggleScan() async {
    if (_scanning) {
      await _ble.stopScan();
      setState(() => _scanning = false);
      return;
    }

    final ok = await BlePermissions.ensureBlePermissions();
    if (!ok) {
      _snack('مجوزهای BLE لازم است');
      return;
    }

    setState(() {
      _found.clear();
      _scanning = true;
    });

    await _ble.startScan(onResult: (r) {
      // بعضی نسخه‌ها: r.advertisementData.advName  —  بعضی دیگر: device.platformName
      final advName = r.advertisementData.advName;
      final name = (advName.isNotEmpty ? advName : r.device.platformName) ?? '';
      if (name.startsWith('SELLER:')) {
        setState(() => _found[name] = r);
      }
    });

    _scanStateSub?.cancel();
    _scanStateSub = FlutterBluePlus.isScanning.listen((s) {
      if (!s && mounted) setState(() => _scanning = false);
    });
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    _scanStateSub?.cancel();
    _ble.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sellers = _found.keys.toList()..sort();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('یافتن فروشنده با بلوتوث', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _toggleScan,
            child: Text(_scanning ? 'توقف جستجو' : 'شروع جستجو'),
          ),
          const SizedBox(height: 8),
          if (sellers.isEmpty)
            Text(_scanning ? 'در حال جستجو…' : 'موردی یافت نشد'),
          for (final name in sellers)
            ListTile(
              leading: const Icon(Icons.store),
              title: Text(name.replaceFirst('SELLER:', 'فروشنده: ')),
              subtitle: const Text('برای انتخاب ضربه بزنید'),
              onTap: () {
                final sellerId = name.substring('SELLER:'.length);
                widget.onPick?.call(sellerId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فروشنده انتخاب شد: $sellerId')),
                );
              },
            ),
        ]),
      ),
    );
  }
}
