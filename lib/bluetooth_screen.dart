import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'elm327_bluetooth.dart';
import 'gauge_screen.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> devices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    // Turn on Bluetooth if off
    await FlutterBluetoothSerial.instance.requestEnable();

    // Get paired devices
    List<BluetoothDevice> bonded =
        await FlutterBluetoothSerial.instance.getBondedDevices();

    setState(() {
      devices = bonded;
      isLoading = false;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GaugeScreen(
          elmAddress: device.address,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Select ELM327 Device"),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
              ? const Center(
                  child: Text(
                    "No Paired Devices Found",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];

                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        title: Text(
                          device.name ?? "Unknown Device",
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          device.address,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        onTap: () => connectToDevice(device),
                      ),
                    );
                  },
                ),
    );
  }
}