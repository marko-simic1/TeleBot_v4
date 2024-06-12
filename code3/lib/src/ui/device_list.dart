import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble_example/src/ble/ble_scanner.dart';
import 'package:provider/provider.dart';
import '../ble/ble_device_connector.dart';
import '../ble/ble_device_interactor.dart';
import 'device_interactor_screen.dart';
import '../ble/ble_logger.dart';
import '../widgets.dart';
import 'device_detail/device_detail_screen.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleScanner, BleScannerState?, BleDeviceConnector>(
        builder: (_, bleScanner, bleScannerState, bleDeviceConnector, __) =>
            _DeviceList(
              scannerState: bleScannerState ??
                  const BleScannerState(
                    discoveredDevices: [],
                    scanIsInProgress: false,
                  ),
              startScan: bleScanner.startScan,
              stopScan: bleScanner.stopScan,
              deviceConnector: bleDeviceConnector,
            ),
      );
}

class _DeviceList extends StatefulWidget {
  const _DeviceList({
    required this.scannerState,
    required this.startScan,
    required this.stopScan,
    required this.deviceConnector,
  });

  final BleDeviceConnector deviceConnector;
  final BleScannerState scannerState;
  final void Function(List<Uuid>) startScan;
  final VoidCallback stopScan;
  @override
  __DeviceListState createState() => __DeviceListState();
}

class __DeviceListState extends State<_DeviceList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 25), // Add space between top of the screen and logo placeholder
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),

            ),
            Flexible(
              child: ListView(
                children: widget.scannerState.discoveredDevices
                    .where((device) => device.name != "") // Filter devices with non-null names
                    .map(
                      (device) => ListTile(
                    title: Text(device.name),
                    subtitle: Text("${device.id}\nRSSI: ${device.rssi}"),
                    leading: const Icon(Icons.bluetooth),
                        onTap: () async {
                          widget.stopScan();
                          widget.deviceConnector.connect(device.id);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceInteractorScreen(
                                deviceId: device.id,
                              ),
                            ),
                          );
                        },
                  ),
                ).toList(), // Convert Iterable to List
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: !widget.scannerState.scanIsInProgress
                      ? () => widget.startScan([])
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50), // Adjust the size according to your requirement
                    backgroundColor: Colors.lightBlueAccent,
                    disabledBackgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Adjust the radius for less roundness
                    ),
                  ),
                  child: Center(
                    child: const Text.rich(
                      TextSpan(
                        text: '', // default text style
                        children: <TextSpan>[
                          TextSpan(text: 'Scan\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          TextSpan(text: 'devices', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10,),
                ElevatedButton(
                  onPressed: widget.scannerState.scanIsInProgress
                      ? widget.stopScan
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(150, 50), // Adjust the size according to your requirement
                    backgroundColor: Colors.lightBlueAccent,
                    disabledBackgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Adjust the radius for less roundness
                    ),
                  ),
                  child: Center(
                    child: const Text.rich(
                      TextSpan(
                        text: '', // default text style
                        children: <TextSpan>[
                          TextSpan(text: 'Stop\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          TextSpan(text: 'scanning', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 25,
            ),
          ],
        ),
      ),
    );
  }
}

