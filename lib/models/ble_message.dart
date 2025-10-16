import 'dart:convert';

/// نوع پیام بین خریدار و فروشنده روی BLE (فقط برای دمو)
enum BleMsgType { payRequest, payReceipt }

class BleMessage {
  final BleMsgType type;
  final String partyId; // sellerId یا buyerId
  final int amount;     // تومان
  final String? note;   // اختیاری (timestamp/nonce/...)

  BleMessage({
    required this.type,
    required this.partyId,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        't': type == BleMsgType.payRequest ? 'REQ' : 'RCPT',
        'id': partyId,
        'amt': amount,
        if (note != null) 'n': note,
      };

  factory BleMessage.fromJson(Map<String, dynamic> j) {
    final t = (j['t'] as String?) ?? 'REQ';
    return BleMessage(
      type: t == 'RCPT' ? BleMsgType.payReceipt : BleMsgType.payRequest,
      partyId: (j['id'] as String?) ?? '',
      amount: (j['amt'] as num?)?.toInt() ?? 0,
      note: j['n'] as String?,
    );
  }

  /// برای انتقال با BLE از UTF8 + Base64 استفاده می‌کنیم
  String encodeBase64() => base64UrlEncode(utf8.encode(jsonEncode(toJson())));

  static BleMessage? tryDecodeBase64(String data) {
    try {
      final raw = utf8.decode(base64Url.decode(data));
      return BleMessage.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }
}
