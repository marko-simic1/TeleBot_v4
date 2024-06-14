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

const _themeColor = Colors.lightGreen;

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
                  // Add your onPressed logic here
                },
                child: const Text('Take a picture'),
              ),
              const SizedBox(height: 20),
              const JoyButtonsExample(joystickIndex: 1),
              const SizedBox(height: 20),
              const JoyButtonsExample(joystickIndex: 2),
            ],
          ),
        ),
      ),
    );
  }
}


class JoyButtonsExample extends StatefulWidget {
  final int joystickIndex;

  const JoyButtonsExample({super.key, required this.joystickIndex});

  @override
  _JoyButtonsExampleState createState() => _JoyButtonsExampleState();
}

class _JoyButtonsExampleState extends State<JoyButtonsExample> {
  List<int> _pressed = [];
  double dimension = 45;

  final double _sizeOfCenter = 0.4;
  final double _numberOfButtons = 4;
  final double _maxButtons = 50;



  final _names = List.generate(26, (index) => String.fromCharCode(index + 65));
  final _colors = [
    Colors.blue,
  ];

  List<Widget> getButtons() {
    return List.generate(_numberOfButtons.round(), (index) {
      var name = _names[index % _names.length];
      var color = _colors[index % _colors.length];
      return testButton(name, color, index);
    });
  }


  GestureDetector testButton(String label, MaterialColor color, int index) {
    return GestureDetector(
      onTap: () {
        sendDataToConnectedDevice(index); // This will send the button index to the connected device
      },
      child: JoyButtonsButton(
        title: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 32)),
        ),
        widgetColor: color,
      ),
    );
  }



  Future<void> sendDataToConnectedDevice(int buttonIndex) async {
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
    final dataToSend = '$buttonIndex';

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





  List<Widget> getIndicators(int number) {
    return List.generate(_numberOfButtons.round(), (index) {
      var name = _names[index % _names.length];
      var color = _colors[index % _colors.length];
      return testIndicator(name, index, color);
    });
  }

  Container testIndicator(String label, int index, Color color) {
    return Container(
      alignment: Alignment.center,
      width: dimension,
      height: dimension,
      color: _pressed.contains(index) ? color : Colors.grey.shade200,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 32)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            children: [
              ...getIndicators(_numberOfButtons.round()),
            ],
          ),
        ),
        JoyButtons(
          centerButtonOutput: List.generate(_numberOfButtons.round(), (index) => index),
          centerWidget: JoyButtonsCenter(size: Size(200 * _sizeOfCenter, 200 * _sizeOfCenter)),
          buttonWidgets: getButtons(),
          listener: (details) {
            setState(() {
              _pressed = details.pressed;
            });
          },
        ),
      ],
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




