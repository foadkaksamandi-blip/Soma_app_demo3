// lib/buyer_main.dart
// اپ خریدار (مرکزی / اسکنر): اسکن BLE، نمایش نتایج، و تلاش برای خواندن manufacturerData

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'services/ble_service.dart';

class BuyerApp extends StatefulWidget {
  const BuyerApp({super.key});

  @override
  State<BuyerApp> createState() => _BuyerAppState();
}

class _BuyerAppState extends State<BuyerApp> {
  final BleService _ble = BleService();

  final List<ScanResult> _found = [];
  StreamSubscription<List<ScanResult>>? _sub;
  bool _scanning = false;
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _listenScanResults();
  }

  void _listenScanResults() {
    _sub = _ble.scanResults.listen((results) {
      // نتایج را به‌صورت یکتا نگه می‌داریم (بر اساس device.id.id)
      final byId = <String, ScanResult>{};
      for (final r in results) {
        byId[r.device.remoteId.str] = r;
      }
      setState(() {
        _found
          ..clear()
          ..addAll(byId.values);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _ensurePermissions() async {
    if (!Platform.isAndroid) return;

    // برای اندروید 12+ مجوزهای BLE، و برای نسخه‌های قدیمی‌تر Location لازم است
    final req = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // برای Android < 12
    ].request();

    // اگر چیزی رد شده بود، وضعیت را آپدیت می‌کنیم (اجباری نیست)
    if (req.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
      setState(() {
        _status = 'Permissions denied';
      });
    }
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        _status = 'Starting scan...';
      });
      await _ensurePermissions();
      await _ble.startScan(timeout: const Duration(seconds: 15));
      setState(() {
        _scanning = true;
        _status = 'Scanning...';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _stopScan() async {
    try {
      await _ble.stopScan();
      setState(() {
        _scanning = false;
        _status = 'Stopped';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  /// از AdvertisementData اولین manufacturerData را به‌صورت Uint8List برمی‌گرداند.
  Uint8List? _extractMfgBytes(AdvertisementData ad) {
    final md = ad.manufacturerData;
    if (md.isEmpty) return null;

    // در FBP نوع مقدار می‌تواند Uint8List یا List<int> باشد
    final firstVal = md.values.first;
    if (firstVal is Uint8List) return firstVal;
    if (firstVal is List<int>) return Uint8List.fromList(firstVal);
    return null;
  }

  /// تلاش برای تفسیر داده‌ی Seller که به‌صورت JSON UTF-8 فرستاده شده
  String _prettyPayload(AdvertisementData ad) {
    try {
      final bytes = _extractMfgBytes(ad);
      if (bytes == null) return '(no manufacturerData)';
      final text = utf8.decode(bytes, allowMalformed: true);
      // اگر JSON بود، قشنگ فرمتش می‌کنیم
      try {
        final dynamic j = jsonDecode(text);
        return const JsonEncoder.withIndent('  ').convert(j);
      } catch (_) {
        return text;
      }
    } catch (e) {
      return 'decode error: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Buyer',
      home: Scaffold(
        appBar: AppBar(title: const Text('SOMA Buyer')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: Text('Status: $_status')),
                  ElevatedButton(
                    onPressed: _scanning ? null : _startScan,
                    child: const Text('Start Scan'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _scanning ? _stopScan : null,
                    child: const Text('Stop Scan'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _found.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final r = _found[i];
                  final ad = r.advertisementData;
                  return ExpansionTile(
                    title: Text(
                      r.device.platformName.isNotEmpty
                          ? r.device.platformName
                          : '(unknown name)',
                    ),
                    subtitle: Text(r.device.remoteId.str),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _prettyPayload(ad),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
