import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// کلیدهای ذخیره‌سازی محلی (SharedPreferences)
const _kBuyerBalance = 'balance_buyer';
const _kSellerBalance = 'balance_seller';
const _kHistory = 'txn_history'; // List<Map>

/// مدل تراکنش نمایشی
class Txn {
  final String role; // buyer | seller
  final int amount;
  final String txnId;
  final int ts;

  Txn(this.role, this.amount, this.txnId, this.ts);

  Map<String, dynamic> toJson() =>
      {'role': role, 'amount': amount, 'txnId': txnId, 'ts': ts};

  static Txn fromJson(Map<String, dynamic> j) =>
      Txn(j['role'], j['amount'], j['txnId'], j['ts']);
}

/// مدیریت موجودی و تاریخچه
class DemoStore {
  DemoStore._();
  static final instance = DemoStore._();

  int buyerBalance = 250000; // مقدار اولیه
  int sellerBalance = 100000; // مقدار اولیه
  List<Txn> history = [];

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    buyerBalance = sp.getInt(_kBuyerBalance) ?? buyerBalance;
    sellerBalance = sp.getInt(_kSellerBalance) ?? sellerBalance;
    final raw = sp.getStringList(_kHistory) ?? [];
    history = raw
        .map((s) => Txn.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kBuyerBalance, buyerBalance);
    await sp.setInt(_kSellerBalance, sellerBalance);
    await sp.setStringList(
      _kHistory,
      history.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  Future<void> addHistory(Txn t) async {
    history.insert(0, t);
    await save();
  }
}

/// قالب ساده مبلغ (تومان)
String formatTomans(int amount) {
  final s = amount.toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idx = s.length - i;
    b.write(s[i]);
    if (idx > 1 && idx % 3 == 1) b.write(',');
  }
  return '${b.toString()} تومان';
}

/// ویجت کارت وضعیت (خاکستری/سبز/قرمز)
class StatusCard extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const StatusCard.waiting({super.key, this.text = 'در انتظار…'})
      : color = const Color(0xFFE0E0E0),
        icon = Icons.hourglass_empty;
  const StatusCard.ok(this.text, {super.key})
      : color = const Color(0xFFC8E6C9),
        icon = Icons.check_circle;
  const StatusCard.error(this.text, {super.key})
      : color = const Color(0xFFFFCDD2),
        icon = Icons.error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(text, textAlign: TextAlign.right)),
          ],
        ),
      ),
    );
  }
}

/// درخواست مجوزهای لازم BLE (Android 12+)
Future<bool> ensureBlePermissions() async {
  final req = <Permission>[
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ];
  final statuses = await req.request();
  return statuses.values.every((s) => s.isGranted);
}

/// شروع/توقف اسکن برای نمایش ساده (دمو)
class BleScanner {
  bool _scanning = false;

  Future<List<ScanResult>> scanOnce() async {
    if (!await ensureBlePermissions()) {
      throw Exception('مجوز بلوتوث لازم است.');
    }
    _scanning = true;
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      final results = FlutterBluePlus.scanResults.value;
      return results;
    } finally {
      await FlutterBluePlus.stopScan();
      _scanning = false;
    }
  }

  bool get isScanning => _scanning;
}
