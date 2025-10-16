import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_permissions.dart';

typedef BuyerDevicePick = void Function(BluetoothDevice device);

/// پنل سادهٔ BLE برای خریدار: وضعیت آداپتور + اسکن و لیست دستگاه‌ها.
class BuyerBlePanel extends StatefulWidget {
  final BuyerDevicePick? onPick;
  const BuyerBlePanel({super.key, this.onPick});

  @override
  State<BuyerBlePanel> createState() => _BuyerBlePanelState();
}

class _BuyerBlePanelState extends State<BuyerBlePanel> {
  bool _scanning = false;
  StreamSubscription<List<ScanResult>>? _sub;
  final List<ScanResult> _results = [];

  Future<void> _toggleScan() async {
    if (_scanning) {
      await FlutterBluePlus.stopScan();
      await _sub?.cancel();
      setState(() {
        _scanning = false;
      });
      return;
    }

    // مجوزها
    final ok = await BlePermissions.ensureBlePermissions();
    if (!ok) {
      _snack('مجوزهای بلوتوث صادر نشد');
      return;
    }

    setState(() {
      _results.clear();
    });

    // استریم نتیجه‌ها
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

    // شروع اسکن
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
    setState(() {
      _scanning = true;
    });

    // وقتی timeout تمام شد، خود پکیج اسکن را می‌بندد اما استریم باز می‌ماند.
    FlutterBluePlus.isScanning.listen((s) {
      if (!s && mounted) {
        setState(() => _scanning = false);
      }
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
            const Text('وضعیت Nearby (بلوتوث)'),
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
                  child: Text(_scanning ? 'توقف اسکن' : 'اسکن دستگاه‌ها'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_results.isEmpty)
              const Text('هنوز دستگاهی پیدا نشده است'),
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
                    leading: const Icon(Icons.bluetooth_searching),
                    title: Text(name),
                    subtitle: Text('${r.device.remoteId.str}  •  RSSI ${r.rssi}'),
                    onTap: widget.onPick == null
                        ? null
                        : () => widget.onPick!(r.device),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
