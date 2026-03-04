import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Elm327Bluetooth {
  BluetoothConnection? connection;
  StreamSubscription<Uint8List>? _subscription;

  final Function(String) onData;

  Elm327Bluetooth({required this.onData});

  Future<void> connect(String address) async {
    try {
      print("Trying to connect to $address");

      connection = await BluetoothConnection.toAddress(address);

      print("BLUETOOTH CONNECTED");

      // Listen for incoming raw data
      _subscription = connection!.input!.listen((Uint8List data) {
        final raw = String.fromCharCodes(data);
        print("RAW RESPONSE: $raw");

        final cleaned =
            raw.replaceAll(RegExp(r'[\r\n>]'), '').trim();

        if (cleaned.isNotEmpty) {
          onData(cleaned);
        }
      });

      // 🔵 Initialize ELM327
      await sendCommand('ATZ');   // Reset
      await Future.delayed(const Duration(seconds: 1));

      await sendCommand('ATE0');  // Echo Off
      await sendCommand('ATL0');  // Linefeed Off
      await sendCommand('ATS0');  // Spaces Off
      await sendCommand('ATH1');  // Headers On

      print("ELM INITIALIZED");

      // 🔥 TEST ECU CONNECTION
      await Future.delayed(const Duration(seconds: 1));
      await sendCommand('0100');   // PID test

      print("SENT 0100");

    } catch (e) {
      print("CONNECTION ERROR: $e");
    }
  }

  Future<void> sendCommand(String cmd) async {
    if (connection != null && connection!.isConnected) {
      print("SENDING: $cmd");
      connection!.output.add(Uint8List.fromList('$cmd\r'.codeUnits));
      await connection!.output.allSent;
    } else {
      print("NOT CONNECTED");
    }
  }

  void disconnect() {
    _subscription?.cancel();
    connection?.finish();
    connection = null;
  }
}