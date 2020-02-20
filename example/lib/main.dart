import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';

void main() => runApp(FlutterGpiodTestApp());

class FlutterGpiodTestApp extends StatefulWidget {
  @override
  _FlutterGpiodTestAppState createState() => _FlutterGpiodTestAppState();
}

class _FlutterGpiodTestAppState extends State<FlutterGpiodTestApp> {
  Future<void> _testFlutterGpiod() async {
    await FlutterGpiod.ensureInitialized();

    /// Retrieve the list of GPIO chips.
    final chips = FlutterGpiod.chips;

    /// Print out all GPIO chips and all lines
    /// for all GPIO chips.
    for (var chip in chips) {
      print("$chip");

      for (var line in chip.lines) {
        print("  ${await line.info}");
      }
    }

    /// Retrieve the line with index 23 of the first chip.
    /// This is BCM pin 23 for the Raspberry Pi.
    ///
    /// In practice, it's better to find the chip you want
    /// based on the chip name, it's just a coincidence
    /// the first chip corresponds to the main Raspberry Pi
    /// GPIO chip here. So `chips.firstWhere((chip) => chip.name == 'brcm2835-pinctrl')`.
    ///
    /// In this case, it's fine because we don't care what
    /// pin really is behind this gpio line.
    final line = chips.first.lines[23];

    /// Request BCM 23 as output.
    await line.requestOutput(consumer: "flutter_gpiod test", initialValue: true);

    /// Pulse the line.
    /// Set it to inactive. (so low voltage = GND)
    await line.setValue(false);
    await Future.delayed(Duration(milliseconds: 500));
    await line.setValue(true);
    await Future.delayed(Duration(milliseconds: 500));

    await line.release();

    /// Now were listening for falling and rising edge events
    /// on BCM 23.
    await line.requestInput(
      consumer: "flutter_gpiod test",
      triggers: {SignalEdge.falling, SignalEdge.rising}
    );

    /// Log line events for eternity.
    await for (final event in line.onEvent) {
      print("flutter_gpiod line event: $event");
    }

    /// Release the line, though we'll never reach this point.
    await line.release();
  }

  @override
  void initState() {
    super.initState();
    _testFlutterGpiod();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_gpiod Test App'),
        ),
        body: Container()
      ),
    );
  }
}
