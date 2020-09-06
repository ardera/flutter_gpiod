import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';

void main() async {
  /// Retrieve the list of GPIO chips.
  final chips = FlutterGpiod.instance.chips;

  /// Print out all GPIO chips and all lines
  /// for all GPIO chips.
  for (var chip in chips) {
    print("$chip");

    for (var line in chip.lines) {
      print("  $line");
    }
  }

  /// Retrieve the line with index 23 of the first chip.
  /// This is BCM pin 23 for the Raspberry Pi.
  ///
  /// I recommend finding the chip you want
  /// based on the chip label, as is done here.
  ///
  /// In this example, we search for the main Raspberry Pi GPIO chip,
  /// which has the label `pinctrl-bcm2835`, and then retrieve the line
  /// with index 23 of it. So [line] is GPIO pin BCM 23.
  final line =
      chips.singleWhere((chip) => chip.label == 'pinctrl-bcm2835').lines[23];

  /// Request BCM 23 as output.
  line.requestOutput(consumer: "flutter_gpiod test", initialValue: false);

  /// Pulse the line 2 times.
  line.setValue(true);
  await Future.delayed(Duration(milliseconds: 500));
  line.setValue(false);
  await Future.delayed(Duration(milliseconds: 500));
  line.setValue(true);
  await Future.delayed(Duration(milliseconds: 500));
  // setValue(false) is not needed since we're releasing it anyway
  line.release();

  /// Now we're listening for falling and rising edge events
  /// on BCM 23.
  line.requestInput(
      consumer: "flutter_gpiod input test",
      triggers: {SignalEdge.falling, SignalEdge.rising});

  print("line value: ${line.getValue()}");

  /// Log line events for eternity.
  await for (final event in line.onEvent) {
    print("flutter_gpiod line event: $event");
  }

  /// Release the line, though we'll never reach this point.
  line.release();
}