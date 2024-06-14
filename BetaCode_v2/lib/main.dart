import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble_example/src/ble/ble_device_connector.dart';
import 'package:flutter_reactive_ble_example/src/ble/ble_device_interactor.dart';
import 'package:flutter_reactive_ble_example/src/ble/ble_scanner.dart';
import 'package:flutter_reactive_ble_example/src/ble/ble_status_monitor.dart';
import 'package:flutter_reactive_ble_example/src/ui/device_list.dart';
import 'package:provider/provider.dart';
import 'package:flutter_joybuttons/flutter_joybuttons.dart';
import 'package:reactive_ble_platform_interface/src/model/uuid.dart' as ReactiveBleUuid;
import 'package:permission_handler/permission_handler.dart';
import 'src/ble/ble_logger.dart';
import 'dart:async';
import 'package:platform_device_id_v3/platform_device_id.dart'; //doda da bi nasa deviceid
import 'package:flutter_joystick/flutter_joystick.dart';

const _themeColor = Colors.lightGreen;
const ballSize = 20.0;
const step = 10.0;

Future<String?> _getInfo() async {
  return await PlatformDeviceId.getDeviceId;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final ble = FlutterReactiveBle();
  final bleLogger = BleLogger(ble: ble);
  final scanner = BleScanner(ble: ble, logMessage: bleLogger.addToLog);
  final monitor = BleStatusMonitor(ble);
  final serviceDiscoverer = BleDeviceInteractor(
    bleDiscoverServices: (deviceId) async {
      await ble.discoverAllServices(deviceId);
      return ble.getDiscoveredServices(deviceId);
    },
    logMessage: bleLogger.addToLog,
    readRssi: ble.readRssi,
  );
  final connector = BleDeviceConnector(
    ble: ble,
    logMessage: bleLogger.addToLog,
    bleDeviceInteractor: serviceDiscoverer,
  );
  final deviceId = _getInfo();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: scanner),
        Provider.value(value: monitor),
        Provider.value(value: connector),
        Provider.value(value: serviceDiscoverer),
        Provider.value(value: bleLogger),
        StreamProvider<BleScannerState?>(
          create: (_) => scanner.state,
          initialData: const BleScannerState(
            discoveredDevices: [],
            scanIsInProgress: false,
          ),
        ),
        StreamProvider<BleStatus?>(
          create: (_) => monitor.state,
          initialData: BleStatus.unknown,
        ),
        StreamProvider<ConnectionStateUpdate>(
          create: (_) => connector.state,
          initialData: const ConnectionStateUpdate(
            deviceId: 'Unknown device',
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Reactive BLE example',
        color: _themeColor,
        theme: ThemeData(primarySwatch: _themeColor),
        home: const HomeScreen(),
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const DeviceListScreen(),
      const JoystickPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Device List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad),
            label: 'Joystick',
          ),
          // Add more BottomNavigationBarItems as needed
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}

class JoystickPage extends StatelessWidget {
  const JoystickPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Joystick Controller'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const JoystickExample()),
                  );
                },
                child: const Text('Joystick'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JoystickExample extends StatefulWidget {
  const JoystickExample({Key? key}) : super(key: key);

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

    // Send updated coordinates to the connected device
    sendDataToConnectedDevice(_x, _y);
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
                },
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.8), // Adjust the position as needed
              child: Joystick(
                mode: _joystickMode,
                listener: (details) {
                  setState(() {
                    _x += step * details.x;
                    _y += step * details.y;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendDataToConnectedDevice(double x, double y) async {
    String? deviceId = await _getInfo();

    if (deviceId == null || deviceId.isEmpty) {
      print("Device ID is null or empty");
      return;
    }

    // Retrieve the BleDeviceInteractor (service discoverer) from the Provider context
    final serviceDiscoverer = Provider.of<BleDeviceInteractor>(context, listen: false);

    // Discover services on the device
    List<Service> discoveredServices = await serviceDiscoverer.discoverServices(deviceId);

    if (discoveredServices.isEmpty) {
      print("No services discovered");
      return;
    }

    Service selectedService = discoveredServices.first;
    String serviceId = selectedService.id.toString();

    if (selectedService.characteristics.isEmpty) {
      print("No characteristics found in the selected service");
      return;
    }

    String characteristicId = selectedService.characteristics.first.id.toString();

    final bleConnector = Provider.of<BleDeviceConnector>(context, listen: false);

    // Construct data to send to the device
    final dataToSend = '$x,$y';

    // Convert the data to bytes
    List<int> dataBytes = utf8.encode(dataToSend);

    // Parse the string UUIDs to Uuid objects
    final serviceUuid = ReactiveBleUuid.Uuid.parse(serviceId);
    final characteristicUuid = ReactiveBleUuid.Uuid.parse(characteristicId);

    // Send data to the connected device
    bleConnector.sendDataToDevice(
      deviceId,
      QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicUuid,
        deviceId: deviceId,
      ),
      dataBytes,
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

Future<void> _requestPermissions() async {
  // Request Bluetooth permission
  await Permission.bluetooth.request();
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.location.request();
}