import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/ble_service.dart';

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  final BleService _ble = BleService();
  bool _isScanning = false;
  String _status = "در انتظار شروع اسکن...";

  /// درخواست مجوزهای بلوتوث و مکان
  Future<void> _checkPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  /// شروع اسکن دستگاه‌ها
  void _startScan() async {
    await _checkPermissions();
    setState(() {
      _isScanning = true;
      _status = "🔍 در حال اسکن دستگاه‌ها...";
    });

    _ble.startScan((device) {
      setState(() {
        _status = "✅ دستگاه پیدا شد: ${device.name.isEmpty ? "بدون نام" : device.name}\nID: ${device.id}";
      });
    });
  }

  /// توقف اسکن
  void _stopScan() {
    _ble.stopScan();
    setState(() {
      _isScanning = false;
      _status = "⛔ اسکن متوقف شد.";
    });
  }

  @override
  void dispose() {
    _ble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SOMA BLE Seller Demo"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isScanning ? _stopScan : _startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                _isScanning ? "توقف اسکن" : "شروع اسکن بلوتوث",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
