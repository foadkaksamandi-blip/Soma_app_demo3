// lib/seller_main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/ble_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Seller Demo',
      theme: ThemeData(
        fontFamily: 'Vazirmatn',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const SellerHomePage(),
    );
  }
}

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  final BleService _ble = BleService();

  StreamSubscription? _scanListen;
  List<String> _seen = <String>[];
  bool _isAdvertising = false;
  bool _hasBluetooth = true;

  @override
  void initState() {
    super.initState();
    _ensurePermissions();
    _scanListen = _ble.scanResults.listen((results) {
      final ids = <String>{..._seen};
      for (final r in results) {
        ids.add(r.device.id.id);
      }
      setState(() => _seen = ids.toList()..sort());
    }, onError: (e) => debugPrint('scanResults error: $e'));
  }

  Future<void> _ensurePermissions() async {
    final perms = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
    for (final p in perms) {
      final st = await p.status;
      if (st.isDenied || st.isRestricted) {
        await p.request();
      }
    }
  }

  Future<void> _startScan() async {
    try {
      await _ble.startScan(timeout: const Duration(seconds: 5));
    } on PlatformException catch (e) {
      debugPrint('startScan error: $e');
      setState(() => _hasBluetooth = false);
    }
  }

  Future<void> _stopScan() async {
    try {
      await _ble.stopScan();
    } catch (e) {
      debugPrint('stopScan error: $e');
    }
  }

  Future<void> _startAdvertising() async {
    try {
      await _ble.startAdvertising(); // بدون پارامتر در v1.1.1
      setState(() => _isAdvertising = true);
    } catch (e) {
      debugPrint('startAdvertising error: $e');
    }
  }

  Future<void> _stopAdvertising() async {
    try {
      await _ble.stopAdvertising();
      setState(() => _isAdvertising = false);
    } catch (e) {
      debugPrint('stopAdvertising error: $e');
    }
  }

  @override
  void dispose() {
    _scanListen?.cancel();
    _ble.stopScan();
    if (_isAdvertising) _ble.stopAdvertising();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Mode (BLE Peripheral & Scanner)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_hasBluetooth)
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.08),
                  border: Border.all(color: Colors.red.withOpacity(.35)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Bluetooth در دسترس نیست یا مجوزها داده نشده‌اند.',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(onPressed: _startScan, child: const Text('Start Scan')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(onPressed: _stopScan, child: const Text('Stop Scan')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAdvertising ? null : _startAdvertising,
                    child: const Text('Start Advertising'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isAdvertising ? _stopAdvertising : null,
                    child: const Text('Stop Advertising'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Seen devices: ${_seen.length}',
                  style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemBuilder: (_, i) => Text(_seen[i]),
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemCount: _seen.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
