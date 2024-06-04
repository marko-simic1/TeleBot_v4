import 'dart:async';
import 'package:flutter_reactive_ble_example/src/ble/ble_device_interactor.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble_example/src/ble/reactive_state.dart';

class BleDeviceConnector extends ReactiveState<ConnectionStateUpdate> {
  BleDeviceConnector({
    required FlutterReactiveBle ble,
    required void Function(String message) logMessage,
    required BleDeviceInteractor bleDeviceInteractor,
  })  : _ble = ble,
        _logMessage = logMessage,
        _bleDeviceInteractor = bleDeviceInteractor;

  final FlutterReactiveBle _ble;
  final void Function(String message) _logMessage;
  final BleDeviceInteractor _bleDeviceInteractor;



  @override
  Stream<ConnectionStateUpdate> get state => _deviceConnectionController.stream;

  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();

  // ignore: cancel_subscriptions
  late StreamSubscription<ConnectionStateUpdate> _connection;

  Future<void> connect(String deviceId) async {
    _logMessage('Start connecting to $deviceId');
    _connection = _ble.connectToDevice(id: deviceId).listen(
          (update) {
        _logMessage(
            'ConnectionState for device $deviceId : ${update.connectionState}');
        _deviceConnectionController.add(update);
      },
      onError: (Object e) =>
          _logMessage('Connecting to device $deviceId resulted in error $e'),
    );
  }

  Future<void> disconnect(String deviceId) async {
    try {
      _logMessage('disconnecting to device: $deviceId');
      await _connection.cancel();
    } on Exception catch (e, _) {
      _logMessage("Error disconnecting from a device: $e");
    } finally {
      // Since [_connection] subscription is terminated, the "disconnected" state cannot be received and propagated
      _deviceConnectionController.add(
        ConnectionStateUpdate(
          deviceId: deviceId,
          connectionState: DeviceConnectionState.disconnected,
          failure: null,
        ),
      );
    }
  }

  Future<void> sendDataToDevice(String deviceId, QualifiedCharacteristic characteristic, List<int> data) async {
    try {
      _logMessage('Sending data to device $deviceId: $data');
      final services = await _bleDeviceInteractor.discoverServices(deviceId);
      await _ble.writeCharacteristicWithResponse(
        characteristic,
        value: data,
      );
    } catch (e) {
      _logMessage('Error sending data to device $deviceId: $e');
    }
  }

  Future<void> dispose() async {
    await _deviceConnectionController.close();
  }
}
