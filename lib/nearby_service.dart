/// Stub برای آماده‌سازی Bluetooth/Nearby.
/// بعداً با پکیج `nearby_connections` تکمیل می‌کنیم تا پرداخت/تأیید آفلاین بین دو اپ
/// بدون اینترنت هم انجام شود.
class NearbyService {
  bool _inited = false;

  Future<void> init() async {
    // TODO: درخواست دسترسی‌های لازم و آماده‌سازی کانال
    _inited = true;
  }

  bool get isReady => _inited;

  Future<bool> startAdvertising(String id) async {
    // TODO: پیاده‌سازی واقعی با nearby_connections
    return _inited;
  }

  Future<bool> startDiscovery() async {
    // TODO: پیاده‌سازی واقعی با nearby_connections
    return _inited;
  }

  Future<void> stopAll() async {
    // TODO: توقف advertise/discover
  }

  Future<bool> sendJson(String deviceId, Map<String, dynamic> data) async {
    // TODO: ارسال پیام JSON
    return _inited;
  }
}
