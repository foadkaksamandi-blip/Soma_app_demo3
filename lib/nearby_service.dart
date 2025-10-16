import 'dart:async';
import 'dart:convert';
import 'package:nearby_connections/nearby_connections.dart';

enum NearbyRole { seller, buyer }

class NearbyService {
  NearbyService(this.role, {required this.endpointName});
  final NearbyRole role;
  final String endpointName;

  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

  String? _remoteId;
  bool _started = false;

  final _connStream = StreamController<String>.broadcast();
  final _msgStream = StreamController<Map<String, dynamic>>.broadcast();

  Stream<String> get connectionState => _connStream.stream;
  Stream<Map<String, dynamic>> get messages => _msgStream.stream;

  bool get isStarted => _started;
  bool get isConnected => _remoteId != null;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    if (role == NearbyRole.seller) {
      // فروشنده تبلیغ می‌کند تا خریدار پیدا کند
      await Nearby().startAdvertising(
        endpointName,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      _connStream.add('Advertising…');
    } else {
      // خریدار به دنبال فروشنده می‌گردد
      await Nearby().startDiscovery(
        'soma.demo.nearby',
        _strategy,
        onEndpointFound: (id, name, serviceId) async {
          if (_remoteId == null) {
            await Nearby().requestConnection(
              endpointName,
              id,
              onConnectionInitiated: _onConnectionInitiated,
              onConnectionResult: _onConnectionResult,
              onDisconnected: _onDisconnected,
            );
          }
        },
        onEndpointLost: (id) {},
      );
      _connStream.add('Discovering…');
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    // اینجا کال‌بک دریافت payload را ثبت می‌کنیم
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES) {
          try {
            final decoded = jsonDecode(utf8.decode(payload.bytes!));
            if (decoded is Map<String, dynamic>) {
              _msgStream.add(decoded);
            }
          } catch (_) {
            // نادیده بگیر
          }
        }
      },
      onPayloadTransferUpdate: (endpointId, update) {
        // در صورت نیاز می‌توان وضعیت انتقال را مانیتور کرد
      },
    );
    _connStream.add('Connecting to ${info.endpointName}');
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      _remoteId = id;
      _connStream.add('Connected');
    } else {
      _connStream.add('Connection failed');
    }
  }

  void _onDisconnected(String id) {
    _remoteId = null;
    _connStream.add('Disconnected');
  }

  /// ارسال پیام JSON به سمت مقابل
  Future<void> sendJson(Map<String, dynamic> data) async {
    if (_remoteId == null) return;
    final bytes = utf8.encode(jsonEncode(data));
    // در نسخه‌های جدید API همین متد موجود است
    await Nearby().sendBytesPayload(_remoteId!, bytes);
  }

  Future<void> stop() async {
    if (!_started) return;
    await Nearby().stopAllEndpoints();
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    _remoteId = null;
    _started = false;
    _connStream.add('Stopped');
  }

  void dispose() {
    _connStream.close();
    _msgStream.close();
  }
}
