# flutter_gpiod

A library for GPIO access on linux using libgpiod.

Currently, `flutter_gpiod` is only supported when using [`flutter-pi`](https://github.com/ardera/flutter-pi).
It will not work on linux desktop or any other platform.

You need to have `libgpiod.so` on your system for it to work.
You can install it using `sudo apt install gpiod`.


## Getting Started

To start using `flutter_gpiod`, ensure it is initialized like this:
```dart
await FlutterGpiod.ensureInitialized();
```

Then, you can retrieve the list of GPIO chips attached to
your system using [FlutterGpiod.chips]. Each chip has a name,
label and a number of GPIO lines associated with it.
```dart
await FlutterGpiod.ensureInitialized();

final chips = FlutterGpiod.chips;

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
await FlutterGpiod.ensureInitialized();

// Get the line with index 22 of the first GPIO chip.
// On Raspberry Pi, this would probably be BCM pin 22,
// but it's not guaranteed, since the first chip is
// not necessarily the main Raspberry Pi GPIO chip.
// To be absolutely sure, search the main GPIO chip
// by its label, like this:
// `chips.firstWhere((chip) => chip.label == "brcm2835-pinctrl")`
final line = FlutterGpiod.chips.first.lines[22];

print("line info: ${await line.info}")
```

To control a line (to read or write values or to listen for edges),
you need to request it using [GpioLine.requestInput] or [GpioLine.requestOutput].
```dart
await FlutterGpiod.ensureInitialized();

final line = FlutterGpiod.chips.first.lines[22];

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