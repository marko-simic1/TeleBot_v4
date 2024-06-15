import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import '/src/ble/ble_device_interactor.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const step = 10.0;

class DeviceInteractorScreen extends StatelessWidget {
  final String deviceId;
  const DeviceInteractorScreen({Key? key, required this.deviceId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer2<ConnectionStateUpdate, BleDeviceInteractor>(
          builder: (_, connectionStateUpdate, deviceInteractor, __) {
            if (connectionStateUpdate.connectionState ==
                DeviceConnectionState.connected) {
              return DeviceInteractor(
                deviceId: deviceId,
                deviceInteractor: deviceInteractor,
              );
            } else if (connectionStateUpdate.connectionState ==
                DeviceConnectionState.connecting) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.autorenew_outlined,
                    size: 30,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Connecting!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 21,
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                    size: 30,
                    color: Colors.red,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Gatt Error!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 30,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class DeviceInteractor extends StatefulWidget {
  final BleDeviceInteractor deviceInteractor;
  final String deviceId;

  const DeviceInteractor(
      {Key? key, required this.deviceInteractor, required this.deviceId})
      : super(key: key);

  @override
  State<DeviceInteractor> createState() => _DeviceInteractorState();
}

class _DeviceInteractorState extends State<DeviceInteractor> {

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 150),
        const Text(
          'Status: Connected!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 350),
        SizedBox(
          width: 200,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JoystickExample(deviceId: widget.deviceId),
                ),
              );
            },
            icon: const Icon(Icons.videogame_asset),
            label: const Text(
              'Joystick',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

class JoystickExample extends StatefulWidget {
  final String deviceId;
  const JoystickExample({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<JoystickExample> createState() => _JoystickExampleState();
}

class _JoystickExampleState extends State<JoystickExample> {
  double _x1 = 0;
  double _y1 = 0;
  double _x2 = 0;
  double _y2 = 0;

  JoystickMode _joystickMode = JoystickMode.all;

  final Uuid _myServiceUuid = Uuid.parse("8b0be1f6-ddd3-11ec-9d64-0242ac120002");
  final Uuid _myCharacteristicUuid = Uuid.parse("ebcb181a-e01f-11ec-9d64-0242ac120002");

  StreamSubscription<List<int>>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToCharacteristic(widget.deviceId);
  }

  void _subscribeToCharacteristic(String deviceId) {
    final deviceInteractor = Provider.of<BleDeviceInteractor>(context, listen: false);
    final characteristic = QualifiedCharacteristic(
      serviceId: _myServiceUuid,
      characteristicId: _myCharacteristicUuid,
      deviceId: deviceId,
    );

    _subscription = deviceInteractor.subScribeToCharacteristic(characteristic).listen(
          (data) {
        // Handle the received data
        final receivedString = utf8.decode(data);
        print('Received data: $receivedString');
      },
      onError: (error) {
        // Handle the error
        print('Error: $error');
      },
    );
  }

  void _onJoystickMove1(double dx, double dy) {
    setState(() {
      _x1 += dx * step;
      _y1 += dy * step;
    });
    print('x1,y1:, $_x1, $_y1');
    _sendData();
  }

  void _onJoystickMove2(double dx, double dy) {
    setState(() {
      _x2 += dx * step;
      _y2 += dy * step;
    });
    print('x2,y2:, $_x2, $_y2');
    _sendData();
  }
  void _sendData() {
    // Define the maximum linear and angular speeds for the turtlesim
    const double maxLinearSpeed = 2.0; // Adjust as needed
    const double maxAngularSpeed = 2.0; // Adjust as needed

    // Scale the joystick values to the turtlesim's range
    double scaledX1 = _x1 * maxLinearSpeed; // Scale X1 for linear speed
    double scaledY1 = _y1 * maxAngularSpeed; // Scale Y1 for angular speed
    double scaledX2 = _x2 * maxLinearSpeed; // Scale X2 for linear speed
    double scaledY2 = _y2 * maxAngularSpeed; // Scale Y2 for angular speed

    // Create the data string to send
    String dataToSend = '${scaledX1.toStringAsFixed(2)},${scaledY1.toStringAsFixed(2)},${scaledX2.toStringAsFixed(2)},${scaledY2.toStringAsFixed(2)}';
    List<int> dataBytes = utf8.encode(dataToSend);

    // Send the data to the connected device
    sendDataToConnectedDevice(dataBytes, widget.deviceId);
  }

/*
  void _sendData() {
    double scaledX1 = (_x1 * 100).clamp(0, 100);
    double scaledY1 = (_y1 * 100).clamp(0, 100);
    double scaledX2 = (_x2 * 100).clamp(100, 200);
    double scaledY2 = (_y2 * 100).clamp(100, 200);

    String dataToSend = '${scaledX1.toInt()},${scaledY1.toInt()},${scaledX2.toInt()},${scaledY2.toInt()}';
    List<int> dataBytes = utf8.encode(dataToSend);

    sendDataToConnectedDevice(dataBytes, widget.deviceId);
  }
*/
  Future<void> sendDataToConnectedDevice(List<int> data, String deviceId) async {
    final deviceInteractor = Provider.of<BleDeviceInteractor>(context, listen: false);

    final characteristic = QualifiedCharacteristic(
      serviceId: _myServiceUuid,
      characteristicId: _myCharacteristicUuid,
      deviceId: deviceId,
    );

    await deviceInteractor.writeCharacterisiticWithoutResponse(characteristic, data);
    print('sent data');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('Joysticks'),
        actions: [
          JoystickModeDropdown(
            mode: _joystickMode,
            onChanged: (JoystickMode value) {
              setState(() {
                _joystickMode = value;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Joystick(
                mode: _joystickMode,
                listener: (details) {
                  _onJoystickMove1(details.x, details.y);
                },
              ),
            ),
            SizedBox(height: 200),
            Center(
              child: Joystick(
                mode: _joystickMode,
                listener: (details) {
                  _onJoystickMove2(details.x, details.y);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JoystickModeDropdown extends StatelessWidget {
  final JoystickMode mode;
  final ValueChanged<JoystickMode> onChanged;

  const JoystickModeDropdown({Key? key, required this.mode, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: FittedBox(
          child: DropdownButton(
            value: mode,
            onChanged: (v) {
              onChanged(v as JoystickMode);
            },
            items: const [
              DropdownMenuItem(value: JoystickMode.all, child: Text('All Directions')),
              DropdownMenuItem(value: JoystickMode.horizontalAndVertical, child: Text('Vertical And Horizontal')),
              DropdownMenuItem(value: JoystickMode.horizontal, child: Text('Horizontal')),
              DropdownMenuItem(value: JoystickMode.vertical, child: Text('Vertical')),
            ],
          ),
        ),
      ),
    );
  }
}
