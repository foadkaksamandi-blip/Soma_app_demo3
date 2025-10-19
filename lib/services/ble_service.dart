import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  Stream<DiscoveredDevice> scanForDevices({required String serviceUuid}) {
    final Uuid uuid = Uuid.parse(serviceUuid);
    return _ble.scanForDevices(withServices: [uuid]);
  }

  Future<void> connectToDevice(String deviceId) async {
    await _ble.connectToAdvertisingDevice(
      id: deviceId,
      prescanDuration: const Duration(seconds: 2),
      withServices: [],
      connectionTimeout: const Duration(seconds: 10),
    ).first;
  }

  Future<void> disconnectDevice(String deviceId) async {
    try {
      await _ble.deinitialize();
    } catch (_) {}
  }

  Future<void> writeData(String deviceId, Uuid characteristicUuid, List<int> value) async {
    await _ble.writeCharacteristicWithoutResponse(
      QualifiedCharacteristic(
        characteristicId: characteristicUuid,
        serviceId: Uuid.parse('0000180F-0000-1000-8000-00805f9b34fb'),
        deviceId: deviceId,
      ),
      value: value,
    );
  }

  Stream<List<int>> readData(String deviceId, Uuid characteristicUuid) {
    return _ble
        .subscribeToCharacteristic(
          QualifiedCharacteristic(
            characteristicId: characteristicUuid,
            serviceId: Uuid.parse('0000180F-0000-1000-8000-00805f9b34fb'),
            deviceId: deviceId,
          ),
        )
        .map((event) => event);
  }
}
