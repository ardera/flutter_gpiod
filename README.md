# flutter_gpiod

A library for GPIO access on linux using libgpiod.

Currently, `flutter_gpiod` is only supports [flutter-pi](https://github.com/ardera/flutter-pi) as a platform.
It will _not_ work on linux desktop or any other platform.

You need to have `libgpiod.so` on your system for it to work.
You can install it using `sudo apt install gpiod`.


## Getting Started

Then, you can retrieve the list of GPIO chips attached to
your system using [FlutterGpiod.chips]. Each chip has a name,
label and a number of GPIO lines associated with it.
```dart
final gpio = await FlutterGpiod.getInstance();

final chips = gpio.chips;

for (final chip in chips) {
    print("chip name: ${chip.name}, chip label: ${chip.label}");

    for (final line in chip.lines) {
        print("  line: $line");
    }
}
```

Each line also has some information associated with it that can be
retrieved using [GpioLine.info].
The information can change at any time if the line is not owned/requested by you.
```dart
// Get the instance of the FlutterGpiod singleton.
final gpio = await FlutterGpiod.getInstance();

// Get the chip with label 'pinctrl-bcm2835'.
// This is the main Raspberry Pi GPIO chip.
final chip = gpio.chips.singleWhere((chip) => chip.label == 'pinctrl-bcm2835');

// Get line 22 of the 'pinctrl-bcm2835' GPIO chip.
// This is the BCM 22 pin of the Raspberry Pi.
final line = chip.lines[22];

print("line info: ${await line.info}")
```

To control a line (to read or write values or to listen for edges),
you need to request it using [GpioLine.requestInput] or [GpioLine.requestOutput].
```dart
final gpio = await FlutterGpiod.getInstance();
final chip = gpio.chips.singleWhere((chip) => chip.label == 'pinctrl-bcm2835');
final line = chip.lines[22];

// request it as input.
await line.requestInput();
print("line value: ${await line.getValue()}");
await line.release();

// now we're requesting it as output.
await line.requestOutput(initialValue: true);
line.setValue(false);
await line.release();

// request it as input again, but this time we're also listening
// for edges; both in this case.
await line.requestInput(triggers: {SignalEdge.falling, SignalEdge.rising});

print("line value: ${await line.getValue()}");

// line.onEvent will not emit any events if no triggers
// are requested for the line.
// this will run forever
await for (final event in line.onEvent) {
  print("got GPIO line signal event: $event");
}

await line.release();
```
