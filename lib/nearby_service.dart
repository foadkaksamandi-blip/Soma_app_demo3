import 'dart:async';
import 'dart:convert';
import 'package:nearby_connections/nearby_connections.dart';

enum NearbyRole { seller, buyer }

class NearbyService {
  NearbyService(this.role, {required this.endpointName});
  final NearbyRole role;
  final String endpointName;

  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

  final _connState = StreamController<String>.broadcast();
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  String? _remoteEndpointId;
  bool _started = false;

  Stream<String> get connectionState => _connState.stream;
  Stream<Map<String, dynamic>> get messages => _messages.stream;
  bool get isStarted => _started;
  bool get isConnected => _remoteEndpointId != null;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    if (role == NearbyRole.seller) {
      await Nearby().startAdvertising(
        endpointName,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: 'soma.demo.nearby',
      );
      _connState.add('در حال پخش (Advertising)…');
    } else {
      await Nearby().startDiscovery(
        'soma.demo.nearby',
        _strategy,
        onEndpointFound: (id, name, serviceId) async {
          // فقط به اولین فروشنده وصل می‌شویم
          if (_remoteEndpointId == null) {
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
      _connState.add('در حال جستجو (Discovery)…');
    }

    Nearby().payloadReceivedCallback = (endpointId, payload) async {
      if (payload.type == PayloadType.BYTES) {
        final jsonStr = String.fromCharCodes(payload.bytes!);
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          _messages.add(map);
        } catch (_) {}
      }
    };
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {},
      onPayloadTransferUpdate: (endpointId, update) {},
    );
    _connState.add('در حال برقراری اتصال با ${info.endpointName}…');
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      _remoteEndpointId = id;
      _connState.add('متصل شد');
    } else {
      _connState.add('اتصال ناموفق');
    }
  }

  void _onDisconnected(String id) {
    _remoteEndpointId = null;
    _connState.add('قطع اتصال');
  }

  Future<bool> sendJson(Map<String, dynamic> data) async {
    if (_remoteEndpointId == null) return false;
    final str = jsonEncode(data);
    final payload = Payload(bytes: str.codeUnits);
    return Nearby().sendPayload(_remoteEndpointId!, payload);
  }

  Future<void> stop() async {
    if (!_started) return;
    await Nearby().stopAllEndpoints();
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    _remoteEndpointId = null;
    _started = false;
    _connState.add('متوقف شد');
  }

  void dispose() {
    _connState.close();
    _messages.close();
  }
}
