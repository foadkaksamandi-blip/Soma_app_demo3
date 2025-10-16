import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';

class NearbyService {
  static const String serviceId = "soma_offline_demo";
  static final Strategy strategy = Strategy.P2P_POINT_TO_POINT;

  static Future<void> stopAll() async {
    try { await Nearby().stopAllEndpoints(); } catch (_) {}
    try { await Nearby().stopAdvertising(); } catch (_) {}
    try { await Nearby().stopDiscovery(); } catch (_) {}
  }

  // Seller → Advertising (پذیرنده)
  static Future<void> startAdvertising({
    required String nickname,
    required void Function(String endpointId, ConnectionInfo info) onConnInit,
    required void Function(String endpointId, String payload) onPayload,
  }) async {
    await stopAll();

    // دریافت payload جهانی
    Nearby().payloadReceivedCallback = (endpointId, payload) async {
      if (payload.type == PayloadType.BYTES && payload.bytes != null) {
        final data = utf8.decode(payload.bytes!);
        onPayload(endpointId, data);
      }
    };

    await Nearby().startAdvertising(
      nickname,
      strategy,
      onConnectionInitiated: (id, info) => onConnInit(id, info),
      onConnectionResult: (id, status) {},
      onDisconnected: (id) {},
      serviceId: serviceId,
    );
  }

  // Buyer → Discovery (یابنده)
  static Future<void> startDiscovery({
    required String nickname,
    required void Function(String endpointId, String endpointName) onEndpointFound,
    required void Function(String endpointId) onEndpointLost,
    required void Function(String endpointId, String payload) onPayload,
  }) async {
    await stopAll();

    // دریافت payload جهانی
    Nearby().payloadReceivedCallback = (endpointId, payload) async {
      if (payload.type == PayloadType.BYTES && payload.bytes != null) {
        final data = utf8.decode(payload.bytes!);
        onPayload(endpointId, data);
      }
    };

    await Nearby().startDiscovery(
      nickname,
      strategy,
      onEndpointFound: (id, name, svc) => onEndpointFound(id, name),
      onEndpointLost: (id) => onEndpointLost(id),
      serviceId: serviceId,
    );
  }

  static Future<void> accept(String endpointId) async {
    await Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (id, payload) {},            // هندل بالا
      onPayloadTransferUpdate: (id, update) {},       // لازم نیست الان
    );
  }

  static Future<void> reject(String endpointId) async {
    await Nearby().rejectConnection(endpointId);
  }

  static Future<void> requestConnection({
    required String endpointId,
    required void Function(String endpointId, ConnectionInfo info) onConnInit,
  }) async {
    await Nearby().requestConnection(
      "buyer",   // نام خریدار در handshake
      endpointId,
      onConnectionInitiated: (id, info) => onConnInit(id, info),
      onConnectionResult: (id, status) {},
      onDisconnected: (id) {},
    );
  }

  static Future<void> sendJson(String endpointId, Map<String, dynamic> json) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    await Nearby().sendBytesPayload(endpointId, bytes);
  }
}
