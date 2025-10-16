import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';

class NearbyService {
  static const Strategy strategy = Strategy.P2P_POINT_TO_POINT;

  Future<void> startAdvertising(
      String userName, Function(String, String) onReceive) async {
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              if (payload.type == PayloadType.BYTES) {
                String message = String.fromCharCodes(payload.bytes!);
                onReceive(endpointId, message);
              }
            },
          );
        },
        onConnectionResult: (id, status) {
          debugPrint('✅ اتصال برقرار شد: $id → $status');
        },
        onDisconnected: (id) {
          debugPrint('❌ اتصال قطع شد: $id');
        },
      );
    } catch (e) {
      debugPrint('⚠️ خطا در تبلیغ: $e');
    }
  }

  Future<void> startDiscovery(
      String userName, Function(String, String) onReceive) async {
    try {
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: (id, info) {
              Nearby().acceptConnection(
                id,
                onPayLoadRecieved: (endpointId, payload) {
                  if (payload.type == PayloadType.BYTES) {
                    String message = String.fromCharCodes(payload.bytes!);
                    onReceive(endpointId, message);
                  }
                },
              );
            },
          );
        },
        onEndpointLost: (id) => debugPrint('🔍 اتصال گم شد: $id'),
      );
    } catch (e) {
      debugPrint('⚠️ خطا در جستجو: $e');
    }
  }

  Future<void> sendData(String id, String message) async {
    try {
      final payload = Payload.fromBytes(message.codeUnits);
      await Nearby().sendPayload(id, payload);
      debugPrint('📤 ارسال شد به $id: $message');
    } catch (e) {
      debugPrint('⚠️ خطا در ارسال: $e');
    }
  }

  void stopAll() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    debugPrint('🛑 تمام ارتباطات متوقف شد');
  }
}
