import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  bool bleConnected = false;
  String connectedDevice = '';
  String lastTxId = '';
  double lastAmount = 0;
  String status = 'در انتظار'; // موفق/ناموفق/در انتظار

  void setConnection(bool ok, {String name = ''}) {
    bleConnected = ok;
    connectedDevice = name;
    notifyListeners();
  }

  void newTx({required String txId, required double amount}) {
    lastTxId = txId;
    lastAmount = amount;
    status = 'در انتظار';
    notifyListeners();
  }

  void setStatus(String s) {
    status = s;
    notifyListeners();
  }

  String genTxId() {
    final id = const Uuid().v4();
    lastTxId = id;
    notifyListeners();
    return id;
  }
}

ThemeData buyerTheme() => ThemeData(
  colorSchemeSeed: const Color(0xFF1565C0),
  useMaterial3: true,
);

ThemeData sellerTheme() => ThemeData(
  colorSchemeSeed: const Color(0xFFEF6C00),
  useMaterial3: true,
);
