import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// مسیر درست سرویس BLE خودتون
import 'package:soma_app_demo3/services/ble_service.dart';

class SellerApp extends StatefulWidget {
  const SellerApp({super.key});

  @override
  State<SellerApp> createState() => _SellerAppState();
}

class _SellerAppState extends State<SellerApp> {
  final BleService _ble = BleService();
  bool _isAdvertising = false;
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _ensurePermissions();
  }

  Future<void> _ensurePermissions() async {
    // برای Android 12+ این‌ها لازم‌اند
    final perms = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      // بعضی دستگاه‌ها هنوز لوکیشن می‌خواهند (زیر Android 12)
      Permission.locationWhenInUse,
    ];

    final results = await perms.request();
    final denied = results.entries.any((e) => e.value.isDenied || e.value.isPermanentlyDenied);
    if (denied && mounted) {
      setState(() => _status = 'Permission denied');
    }
  }

  Future<void> _start() async {
    try {
      setState(() => _status = 'Starting advertising…');

      // داده‌ی نمونه‌ی Manufacturer (می‌توانید payload واقعی خودتان را بسازید)
      final payload = Uint8List.fromList([0x53, 0x4F, 0x4D, 0x41]); // "SOMA"
      await _ble.startAdvertising(
        manufacturerData: payload,
        manufacturerId: 0xFFFF,
        localName: 'SOMA-SELLER',
      );

      if (mounted) {
        setState(() {
          _isAdvertising = true;
          _status = 'Advertising';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _stop() async {
    try {
      setState(() => _status = 'Stopping…');
      await _ble.stopAdvertising();
      if (mounted) {
        setState(() {
          _isAdvertising = false;
          _status = 'Stopped';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Seller',
      theme: ThemeData(
        fontFamily: 'Vazirmatn',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('SOMA — Seller')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(_status)),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(_isAdvertising ? 'Advertising ON' : 'Advertising OFF'),
                value: _isAdvertising,
                onChanged: (v) => v ? _start() : _stop(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isAdvertising ? null : _start,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAdvertising ? _stop : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text('BLE Peripheral uses flutter_ble_peripheral 1.2.6',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
