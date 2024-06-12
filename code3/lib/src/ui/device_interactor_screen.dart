import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import '/src/ble/ble_device_interactor.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'dart:async';

const ballSize = 20.0;
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
                  Icon(Icons.autorenew_outlined, // Add icon
                    size: 30, // Adjust icon size as needed
                    color: Colors.black87,
                  ),
                  SizedBox(width: 5), // Add some space between icon and text
                  Text(
                    'Connecting!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 21, // Increase the font size
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, // Add icon
                    size: 30, // Adjust icon size as needed
                    color: Colors.red,
                  ),
                  SizedBox(width: 5), // Add some space between icon and text
                  Text(
                    'Gatt Error!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 30, // Increase the font size
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
  final Uuid _myServiceUuid =
  Uuid.parse("57d9b5e7-605a-43ce-b25d-59fff4bca211");
  final Uuid _myCharacteristicUuid =
  Uuid.parse("bc944239-6e0e-40cb-be0a-a4e693db9172");

  final Uuid _anotherServiceUuid =  Uuid.parse("57d9b5e7-605a-43ce-b25d-59fff4bca211");
  final Uuid _anotherCharacteristicUuid =  Uuid.parse("bc944239-6e0e-40cb-be0a-a4e693db9172");

  Stream<List<int>>? subscriptionStream;
  Stream<List<int>>? anotherSubscriptionStream;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 150),
        // Add space between the top of the screen and the "connected" text
        const Text(
          'Status: Connected!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 24, // Increase the font size
          ),
        ),
        const SizedBox(height: 350), // Add space between text and button
        SizedBox(
          width: 200, // Set the desired width
          height: 60, // Set the desired height
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JoystickExample(deviceId: widget.deviceId),
                ),
              );
            },
            icon: const Icon(Icons.videogame_asset), // Use an appropriate icon
            label: const Text(
              'Joystick',
              style: TextStyle(
                fontSize: 20, // Increase the font size of the button text
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16), // Adjust padding for larger button
            ),
          ),
        ),
      ],
    );
  }
}


class JoystickExample extends StatefulWidget {
  final String deviceId; // Add this line
  const JoystickExample({Key? key, required this.deviceId}) : super(key: key); // Modify constructor

  @override
  State<JoystickExample> createState() => _JoystickExampleState();
}


class _JoystickExampleState extends State<JoystickExample> {
  double _x = 100;
  double _y = 350;
  JoystickMode _joystickMode = JoystickMode.all;

  @override
  void didChangeDependencies() {
    _x = MediaQuery.of(context).size.width / 2 - ballSize / 2;
    super.didChangeDependencies();
  }


  void _onJoystickMove(double dx, double dy) {
    setState(() {
      _x += dx * step;
      _y += dy * step;
    });

    sendDataToConnectedDevice(_x, _y, widget.deviceId);
  }


  Future<void> sendDataToConnectedDevice(double x, double y, String deviceId) async {
    final deviceInteractor = Provider.of<BleDeviceInteractor>(context, listen: false);

    final dataToSend = '$x,$y';

    List<int> dataBytes = utf8.encode(dataToSend);

    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse("57d9b5e7-605a-43ce-b25d-59fff4bca211"),
      characteristicId: Uuid.parse("bc944239-6e0e-40cb-be0a-a4e693db9172"),
      deviceId: deviceId,
    );

    await deviceInteractor.writeCharacterisiticWithResponse(characteristic, dataBytes);
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
        child: Stack(
          children: [
            Container(
              color: Colors.grey,
            ),
            Ball(_x, _y),
            Align(
              alignment: const Alignment(0, 0.8),
              child: Joystick(
                mode: _joystickMode,
                listener: (details) {
                  setState(() {
                    _x += step * details.x;
                    _y += step * details.y;
                  });
                  _onJoystickMove(details.x, details.y);
                },
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.8),
              child: Joystick(
                mode: _joystickMode,
                listener: (details) {
                  setState(() {
                    _x += step * details.x;
                    _y += step * details.y;
                  });
                  _onJoystickMove(details.x, details.y);
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

  const JoystickModeDropdown(
      {Key? key, required this.mode, required this.onChanged})
      : super(key: key);

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
              DropdownMenuItem(
                  value: JoystickMode.all, child: Text('All Directions')),
              DropdownMenuItem(
                  value: JoystickMode.horizontalAndVertical,
                  child: Text('Vertical And Horizontal')),
              DropdownMenuItem(
                  value: JoystickMode.horizontal, child: Text('Horizontal')),
              DropdownMenuItem(
                  value: JoystickMode.vertical, child: Text('Vertical')),
            ],
          ),
        ),
      ),
    );
  }
}

class Ball extends StatelessWidget {
  final double x;
  final double y;

  const Ball(this.x, this.y, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: ballSize,
        height: ballSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey,

        ),
        child: Icon(
          Icons.api_rounded,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }
}



