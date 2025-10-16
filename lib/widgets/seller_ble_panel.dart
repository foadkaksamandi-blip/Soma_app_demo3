import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_permissions.dart';

/// پنل سادهٔ BLE برای فروشنده.
/// فعلاً فقط وضعیت و اسکن نمایش می‌دهیم (بدون advertise تا با پکیج‌ها ناسازگار نشود).
class SellerBlePanel extends StatefulWidget {
  final String sellerId;
  const SellerBlePanel({super.key, required this.sellerId});

  @override
  State<SellerBlePanel> createState() => _SellerBlePanelState();
}

class _SellerBlePanelState extends State<SellerBlePanel> {
  bool _scanning = false;
  StreamSubscription<List<ScanResult>>? _sub;
  final List<ScanResult> _results = [];

  Future<void> _toggleScan() async {
    if (_scanning) {
      await FlutterBluePlus.stopScan();
      await _sub?.cancel();
      setState(() => _scanning = false);
      return;
    }

    final ok = await BlePermissions.ensureBlePermissions();
    if (!ok) {
      _snack('مجوزهای بلوتوث صادر نشد');
      return;
    }

    setState(() => _results.clear());

    _sub = FlutterBluePlus.scanResults.listen((batch) {
      setState(() {
        for (final r in batch) {
          final idx = _results.indexWhere((e) => e.device.remoteId == r.device.remoteId);
          if (idx >= 0) {
            _results[idx] = r;
          } else {
            _results.add(r);
          }
        }
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
    setState(() => _scanning = true);

    FlutterBluePlus.isScanning.listen((s) {
      if (!s && mounted) setState(() => _scanning = false);
    });
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BLE فروشنده (ID: ${widget.sellerId})'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.bluetooth),
                const SizedBox(width: 8),
                Expanded(
                  child: StreamBuilder<BluetoothAdapterState>(
                    stream: FlutterBluePlus.adapterState,
                    initialData: BluetoothAdapterState.unknown,
                    builder: (context, snap) {
                      final st = snap.data ?? BluetoothAdapterState.unknown;
                      final on = st == BluetoothAdapterState.on;
                      return Text(on ? 'روشن' : 'خاموش');
                    },
                  ),
                ),
                FilledButton(
                  onPressed: _toggleScan,
                  child: Text(_scanning ? 'توقف اسکن' : 'اسکن نزدیک‌ها'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_results.isEmpty)
              const Text('دستگاهی مشاهده نشد'),
            if (_results.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 8),
                itemBuilder: (context, i) {
                  final r = _results[i];
                  final name = r.device.platformName.isNotEmpty
                      ? r.device.platformName
                      : '(بدون‌نام)';
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.device_hub),
                    title: Text(name),
                    subtitle: Text('${r.device.remoteId.str}  •  RSSI ${r.rssi}'),
                  );
                },
              ),
            const SizedBox(height: 6),
            const Text(
              'نکته: تبلیغ (Advertise) BLE هنوز فعال نشده است تا با پکیج‌های پایدار ناسازگار نشود.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
