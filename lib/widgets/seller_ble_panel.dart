import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../services/ble_permissions.dart';

class SellerBlePanel extends StatefulWidget {
  final String sellerId;
  const SellerBlePanel({super.key, required this.sellerId});

  @override
  State<SellerBlePanel> createState() => _SellerBlePanelState();
}

class _SellerBlePanelState extends State<SellerBlePanel> {
  final _ble = BleService();
  bool _advertising = false;
  String _status = 'خاموش';

  Future<void> _toggle() async {
    try {
      if (!_advertising) {
        final ok = await ensureBlePermissions();
        if (!ok) {
          setState(() => _status = 'اجازه‌های BLE رد شد');
          return;
        }
        await _ble.startAdvertisingSeller(widget.sellerId);
        setState(() {
          _advertising = true;
          _status = 'در حال پخش (SELLER:${widget.sellerId})';
        });
      } else {
        await _ble.stopAdvertising();
        setState(() {
          _advertising = false;
          _status = 'خاموش';
        });
      }
    } catch (e) {
      setState(() => _status = 'خطا: $e');
    }
  }

  @override
  void dispose() {
    _ble.stopAdvertising();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('بلوتوث فروشنده', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('وضعیت: $_status'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _toggle,
              child: Text(_advertising ? 'خاموش کردن پخش BLE' : 'روشن کردن پخش BLE'),
            ),
          ],
        ),
      ),
    );
  }
}
