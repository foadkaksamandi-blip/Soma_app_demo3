import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

/// companyId سفارشی برای manufacturer data.
/// برای دمو از 0xFFFF استفاده می‌کنیم.
const int _kMfgId = 0xFFFF;

/// سرویس BLE برای دمو (Seller: Advertise / Buyer: Scan)
class BleService {
  // ---------------- SELLER (Advertise) ----------------
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  /// شروع تبلیغ BLE با payload رسید (مثلاً: {"type":"RECEIPT","sellerId":"...","amount":10000})
  Future<void> startAdvertising(Map<String, dynamic> payload) async {
    final String jsonStr = jsonEncode(payload);
    final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonStr));

    final AdvertiseData data = AdvertiseData(
      includeDeviceName: false,
      manufacturerId: _kMfgId,
      manufacturerData: bytes,
    );

    final AdvertiseSettings settings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeBalanced,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
      timeoutSeconds: 0, // 0 = بدون تایم‌اوت (تا وقتی stopAdvertising صدا بخورد)
      connectable: false,
    );

    await _peripheral.start(advertiseData: data, advertiseSettings: settings);
  }

  Future<void> stopAdvertising() async {
    await _peripheral.stop();
  }

  // ---------------- BUYER (Scan) ----------------
  StreamSubscription<List<ScanResult>>? _scanSub;

  /// شروع اسکن و واکشی رسید از manufacturer data با companyId مشخص
  Future<void> startScan({
    required void Function(Map<String, dynamic> payload) onReceiptFound,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // گوش‌کردن به نتایج اسکن
    _scanSub = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (final ScanResult r in results) {
        final md = r.advertisementData.manufacturerData;
        if (md.containsKey(_kMfgId)) {
          try {
            final bytes = md[_kMfgId]!;
            final String jsonStr = utf8.decode(bytes);
            final Map<String, dynamic> payload = jsonDecode(jsonStr);
            onReceiptFound(payload);
          } catch (_) {
            // payload قابل‌خواندن نبود، رد می‌کنیم
          }
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidScanMode: AndroidScanMode.balanced,
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
  }
}
