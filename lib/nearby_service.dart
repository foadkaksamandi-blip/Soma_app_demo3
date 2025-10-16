import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

enum PeerRole { seller, buyer }

class SomaMessage {
  final String type;
  final Map<String, dynamic> data;
  SomaMessage(this.type, this.data);

  Map<String, dynamic> toJson() => {'type': type, 'data': data};

  static SomaMessage fromJson(String jsonStr) {
    final m = json.decode(jsonStr) as Map<String, dynamic>;
    return SomaMessage(m['type'] as String, (m['data'] as Map).cast());
  }
}

class NearbyService {
  NearbyService._();
  static final NearbyService I = NearbyService._();

  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;
  static const String _serviceId = 'com.soma.offline.demo';

  late PeerRole _role;
  late String _localUserName;
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  String? _connectedEndpointId;

  final _logCtrl = StreamController<String>.broadcast();
  final _msgCtrl = StreamController<SomaMessage>.broadcast();
  Stream<String> get logs => _logCtrl.stream;
  Stream<SomaMessage> get messages => _msgCtrl.stream;

  void _log(String s) {
    if (kDebugMode) print('[Nearby] $s');
    _logCtrl.add(s);
  }

  Future<void> init({
    required PeerRole role,
    required String localUserName,
  }) async {
    _role = role;
    _localUserName = localUserName;

    // ثبت callback‌ها برای API قدیمی
    Nearby().payloadReceivedCallback = (endpointId, payload) async {
      if (payload.type == PayloadType.BYTES) {
        final bytes = payload.bytes!;
        final str = utf8.decode(bytes);
        _log('RX from $endpointId: $str');
        try {
          final msg = SomaMessage.fromJson(str);
          _msgCtrl.add(msg);
        } catch (e) {
          _log('Parse error: $e');
        }
      }
    };

    Nearby().payloadTransferUpdateCallback = (endpointId, update) {
      if (update.status == PayloadStatus.SUCCESS) {
        _log('Transfer SUCCESS (id=${update.payloadId})');
      } else if (update.status == PayloadStatus.FAILURE) {
        _log('Transfer FAILURE (id=${update.payloadId})');
      }
    };

    Nearby().disconnectedCallback = (endpointId) {
      if (_connectedEndpointId == endpointId) _connectedEndpointId = null;
      _log('Disconnected: $endpointId');
    };
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;
    _log('Start advertising as $_localUserName');

    final ok = await Nearby().startAdvertising(
      _localUserName,
      _strategy,
      serviceId: _serviceId,
      onConnectionInitiated: (id, info) async {
        _log('Conn initiated by $id -> accept');
        await Nearby().acceptConnection(id,
            onPayLoadRecieved: (eid, payload) async {
          if (payload.type == PayloadType.BYTES) {
            final str = utf8.decode(payload.bytes!);
            _log('RX (adv): $str');
            final msg = SomaMessage.fromJson(str);
            _msgCtrl.add(msg);
          }
        }, onPayloadTransferUpdate: (eid, update) {
          if (update.status == PayloadStatus.SUCCESS) {
            _log('Transfer done to $eid');
          }
        });
      },
      onConnectionResult: (id, status) {
        _log('Conn result adv $id: $status');
        if (status == Status.CONNECTED) _connectedEndpointId = id;
      },
      onDisconnected: (id) {
        _log('Disconnected(adv): $id');
        if (_connectedEndpointId == id) _connectedEndpointId = null;
      },
    );

    _isAdvertising = ok;
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    _log('Start discovery as $_localUserName');

    final ok = await Nearby().startDiscovery(
      _localUserName,
      _strategy,
      serviceId: _serviceId,
      onEndpointFound: (id, name, serviceId) async {
        _log('Found endpoint: $id ($name) -> requestConnection');
        await Nearby().requestConnection(
          _localUserName,
          id,
          onConnectionInitiated: (rid, info) async {
            _log('Conn initiated with $rid -> accept');
            await Nearby().acceptConnection(rid,
                onPayLoadRecieved: (eid, payload) async {
              if (payload.type == PayloadType.BYTES) {
                final str = utf8.decode(payload.bytes!);
                _log('RX (disc): $str');
                final msg = SomaMessage.fromJson(str);
                _msgCtrl.add(msg);
              }
            }, onPayloadTransferUpdate: (eid, update) {});
          },
          onConnectionResult: (rid, status) {
            _log('Conn result disc $rid: $status');
            if (status == Status.CONNECTED) _connectedEndpointId = rid;
          },
          onDisconnected: (rid) {
            _log('Disconnected(disc): $rid');
            if (_connectedEndpointId == rid) _connectedEndpointId = null;
          },
        );
      },
      onEndpointLost: (id) {
        _log('Endpoint lost: $id');
      },
    );

    _isDiscovering = ok;
  }

  Future<void> stopAll() async {
    _log('Stop all');
    _isAdvertising = false;
    _isDiscovering = false;
    _connectedEndpointId = null;
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
  }

  Future<bool> sendMessage(SomaMessage msg) async {
    final endpoint = _connectedEndpointId;
    if (endpoint == null) {
      _log('No connected endpoint');
      return false;
    }
    final jsonStr = json.encode(msg.toJson());
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    _log('TX: $jsonStr');
    try {
      await Nearby().sendBytesPayload(endpoint, bytes);
      return true;
    } catch (e) {
      _log('Send error: $e');
      return false;
    }
  }
}
