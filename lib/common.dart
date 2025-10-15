import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrPayload {
  final String type; // 'sell_request' یا 'payment_proof'
  final String sellerId;
  final String? buyerId;
  final int amount; // تومان
  final int ts; // timestamp millis
  final String? nonce; // برای جلوگیری از ری‌پلی
  final String? sig; // امضا/هش ساده برای دمو

  QrPayload({
    required this.type,
    required this.sellerId,
    this.buyerId,
    required this.amount,
    required this.ts,
    this.nonce,
    this.sig,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'sellerId': sellerId,
        if (buyerId != null) 'buyerId': buyerId,
        'amount': amount,
        'ts': ts,
        if (nonce != null) 'nonce': nonce,
        if (sig != null) 'sig': sig,
      };

  static QrPayload fromJson(Map<String, dynamic> j) => QrPayload(
        type: j['type'],
        sellerId: j['sellerId'],
        buyerId: j['buyerId'],
        amount: j['amount'],
        ts: j['ts'],
        nonce: j['nonce'],
        sig: j['sig'],
      );
}

// هش ساده برای دمو (در محصول واقعی از امضای نامتقارن استفاده کنید)
String makeSig({
  required String sellerId,
  String? buyerId,
  required int amount,
  required int ts,
  required String secret, // در دمو یک رشته ثابت
}) {
  final raw = '$sellerId|${buyerId ?? ''}|$amount|$ts|$secret';
  return sha256.convert(utf8.encode(raw)).toString();
}
