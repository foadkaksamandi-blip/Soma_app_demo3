import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

/// نقش دستگاه در دمو
enum PeerRole { seller, buyer }

/// پیام ساده برای تبادل بین خریدار/فروشنده
class SomaMessage {
  final String type; // e.g. 'payment_request', 'payment_receipt'
  final Map<String, dynamic> data;

  SomaMessage(this.type, this.data);

  Map<String, dynamic> toJson() => {'type': type, 'data': data};

  static SomaMessage fromJson(String jsonStr) {
    final m = json.decode(jsonStr) as Map<String, dynamic>;
    return SomaMessage(m['type'] as String, (m['data'] as Map).cast());
  }
}

/// سرویس مدیریت Nearby Connections
class NearbyService {
  NearbyService._();
  static final NearbyService I = NearbyService._();

  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;
  static const String _serviceId = 'com.soma.offline.demo';

  late PeerRole _role;
  late String _localUserName;
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  /// آخرین endpoint متصل (در این دمو یک به یک)
  String? _connectedEndpointId;

  // Streamهایی برای UI
  final _logCtrl = StreamController<String>.broadcast();
  final _msgCtrl = StreamController<SomaMessage>.broadcast();
  Stream<String> get logs => _logCtrl.stream;
  Stream<SomaMessage> get messages => _msgCtrl.stream;

  void _log(String s) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Nearby] $s');
    }
    _logCtrl.add(s);
  }

  /// آماده‌سازی سرویس
  Future<void> init({
    required PeerRole role,
    required String localUserName,
  }) async {
    _role = role;
    _localUserName = localUserName;

    // گوش‌دادن به دریافت payloadها (API جدید)
    Nearby().onPayloadReceivedStream.listen((payloadData) async {
      final endpointId = payloadData.endpointId;
      final payload = payloadData.payload;

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
    });

    Nearby().onPayloadTransferUpdateStream.listen((update) {
      // اینجا اگر نیاز بود می‌توانی وضعیت انتقال را به UI بدهی
      // e.g. inProgress / success / failure
      if (update.status == PayloadStatus.SUCCESS) {
        _log('Transfer SUCCESS (id=${update.payloadId})');
      } else if (update.status == PayloadStatus.FAILURE) {
        _log('Transfer FAILURE (id=${update.payloadId})');
      }
    });

    // برای دیسکانکت شدن
    Nearby().onDisconnectedStream.listen((id) {
      if (_connectedEndpointId == id) {
        _connectedEndpointId = null;
      }
      _log('Disconnected: $id');
    });
  }

  /// شروع تبلیغ (برای فروشنده)
  Future<void> startAdvertising() async {
    if (_isAdvertising) return;
    _log('Start advertising as $_localUserName');
    final ok = await Nearby().startAdvertising(
      _localUserName,
      _strategy,
      serviceId: _serviceId,
      onConnectionInitiated: (id, info) async {
        _log('Conn initiated by $id (${info.endpointName}) -> accept');
        await Nearby().acceptConnection(
          id,
          onPayLoadRecieved: (eid, payload) {
            // این callback همچنان توسط کتابخانه فراخوانی می‌شود؛
            // اما ما listener سراسری را هم داریم.
          },
          onPayloadTransferUpdate: (eid, update) {},
        );
      },
      onConnectionResult: (id, status) {
        _log('Conn result $id: $status');
        if (status == Status.CONNECTED) _connectedEndpointId = id;
      },
      onDisconnected: (id) {
        _log('Disconnected(advertising): $id');
        if (_connectedEndpointId == id) _connectedEndpointId = null;
      },
    );

    _isAdvertising = ok;
  }

  /// شروع کشف (برای خریدار)
  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    _log('Start discovery as $_localUserName');
    final ok = await Nearby().startDiscovery(
      _localUserName,
      _strategy,
      serviceId: _serviceId,
      onEndpointFound: (id, name, serviceId) async {
        _log('Found endpoint: $id ($name) / $serviceId -> requestConnection');
        await Nearby().requestConnection(
          _localUserName,
          id,
          onConnectionInitiated: (rid, info) async {
            _log('Conn initiated with $rid -> accept');
            await Nearby().acceptConnection(
              rid,
              onPayLoadRecieved: (eid, payload) {},
              onPayloadTransferUpdate: (eid, update) {},
            );
          },
          onConnectionResult: (rid, status) {
            _log('Conn result discovery $rid: $status');
            if (status == Status.CONNECTED) _connectedEndpointId = rid;
          },
          onDisconnected: (rid) {
            _log('Disconnected(discovery): $rid');
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

  /// توقف همه چیز
  Future<void> stopAll() async {
    _log('Stop all');
    _isAdvertising = false;
    _isDiscovering = false;
    _connectedEndpointId = null;
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
  }

  /// ارسال پیام JSON (رشته‌ای) به طرف مقابل
  Future<bool> sendMessage(SomaMessage msg) async {
    final endpoint = _connectedEndpointId;
    if (endpoint == null) {
      _log('No connected endpoint to send');
      return false;
    }
    final jsonStr = json.encode(msg.toJson());
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    _log('TX to $endpoint: $jsonStr');
    try {
      return await Nearby().sendBytesPayload(endpoint, bytes);
    } catch (e) {
      _log('Send error: $e');
      return false;
    }
  }
}
