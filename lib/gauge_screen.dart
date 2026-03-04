import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:intl/intl.dart';
import 'elm327_bluetooth.dart';

class GaugeScreen extends StatefulWidget {
  final String elmAddress;

  const GaugeScreen({super.key, required this.elmAddress});

  @override
  State<GaugeScreen> createState() => _GaugeScreenState();
}

class _GaugeScreenState extends State<GaugeScreen> {
  late Elm327Bluetooth elm;

  // OBD data
  double rpm = 0;
  double speed = 0;
  double coolant = 0;
  double throttle = 0;
  double cvtTemp = 0;
  double oilTemp = 0;
  int gear = 0;
  int vvtStatus = 0;

  bool isConnected = false;
  bool _busy = false;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    elm = Elm327Bluetooth(onData: _handleElmData);

    _connect();
  }

  Future<void> _connect() async {
    await elm.connect(widget.elmAddress);

    setState(() {
      isConnected = true;
    });

    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (timer) async {
        if (!_busy && isConnected) {
          _busy = true;

          // Example PIDs
          await elm.sendCommand('010C'); // RPM
          await Future.delayed(const Duration(milliseconds: 50));

          await elm.sendCommand('010D'); // Speed
          await Future.delayed(const Duration(milliseconds: 50));

          await elm.sendCommand('0105'); // Coolant
          await Future.delayed(const Duration(milliseconds: 50));

          await elm.sendCommand('0111'); // Throttle %
          await Future.delayed(const Duration(milliseconds: 50));

          await elm.sendCommand('0130'); // CVT Temp (example)
          await Future.delayed(const Duration(milliseconds: 50));

          await elm.sendCommand('010F'); // Oil Temp
          await Future.delayed(const Duration(milliseconds: 50));

          await elm.sendCommand('0142'); // VVT Status (example)
          await Future.delayed(const Duration(milliseconds: 50));

          _busy = false;
        }
      },
    );
  }

  void _handleElmData(String data) {
    // Parse OBD responses
    if (data.startsWith('410C')) {
      final bytes = data.substring(4);
      final A = int.parse(bytes.substring(0, 2), radix: 16);
      final B = int.parse(bytes.substring(2, 4), radix: 16);
      setState(() => rpm = ((A * 256) + B) / 4);
    }

    if (data.startsWith('410D')) {
      final value = int.parse(data.substring(4, 6), radix: 16).toDouble();
      setState(() => speed = value);
    }

    if (data.startsWith('4105')) {
      final value = int.parse(data.substring(4, 6), radix: 16) - 40;
      setState(() => coolant = value.toDouble());
    }

    if (data.startsWith('4111')) {
      final value = int.parse(data.substring(4, 6), radix: 16).toDouble();
      setState(() => throttle = value);
    }

    if (data.startsWith('4130')) {
      final value = int.parse(data.substring(4, 6), radix: 16).toDouble();
      setState(() => cvtTemp = value);
    }

    if (data.startsWith('410F')) {
      final value = int.parse(data.substring(4, 6), radix: 16) - 40;
      setState(() => oilTemp = value.toDouble());
    }

    if (data.startsWith('4142')) {
      final value = int.parse(data.substring(4, 6), radix: 16);
      setState(() => vvtStatus = value);
    }

    // Gear can be derived from speed/RPM and CVT logic or additional PID
    // setState(() => gear = ...);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    elm.disconnect();
    super.dispose();
  }

  // ===================== GAUGES =====================
  Widget buildGauge(
      String title, double value, double min, double max, double redline,
      {double size = 300}) {
    return SizedBox(
      width: size,
      height: size,
      child: SfRadialGauge(
        axes: [
          RadialAxis(
            minimum: min,
            maximum: max,
            interval: ((max - min) / 6).roundToDouble(),
            numberFormat: NumberFormat("##0"),
            axisLabelStyle: GaugeTextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size / 15,
            ),
            axisLineStyle: AxisLineStyle(
              thickness: 0.07 * size,
              color: Colors.white24,
            ),
            pointers: [
              NeedlePointer(
                value: value,
                enableAnimation: true,
                needleColor: Colors.white,
              ),
            ],
            annotations: [
              GaugeAnnotation(
                widget: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size / 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                angle: 90,
                positionFactor: 0.85,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildVvtIndicator({double size = 300}) {
    final bool isOn = vvtStatus == 1;
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: isOn ? Colors.red.withOpacity(0.2) : Colors.black
        ),
        child: Center(
          child: Text(
            isOn ? "VVT ON" : "VVT",
            style: TextStyle(
              fontSize: size / 10,
              fontWeight: FontWeight.bold,
              color: isOn ? Colors.redAccent : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDashboard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          "GEAR ${gear.toInt()}",
          style: const TextStyle(
              fontSize: 60,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildGauge("RPM", rpm, 0, 9000, 6200),
            buildGauge("Coolant", coolant, 40, 120, 105),
            buildGauge("Throttle", throttle, 0, 100, 90),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildGauge("CVT Temp", cvtTemp, 40, 140, 120),
            buildVvtIndicator(),
            buildGauge("Oil Temp", oilTemp, 40, 130, 115),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 1280,
          height: 720,
          child: buildDashboard(),
        ),
      ),
    );
  }
}