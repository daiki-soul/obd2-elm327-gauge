import 'package:flutter/material.dart';
import 'bluetooth_screen.dart'; // Make sure you created this

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BluetoothScreen(), // Start here, not GaugeScreen
    );
  }
}