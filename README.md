# 📰 NEWS
- If you have root access, works on Android too (See issue [#9](https://github.com/ardera/flutter_gpiod/issues/9#issuecomment-689112840))
- even though the name seems to imply otherwise, the flutter SDK is not required to use this package.
- `libgpiod` is no longer required
- a lot of the `async` stuff has gone away, making it nicer & easier to use
- The package uses FFI with ioctls now, which should result in lower latency. (The event listener isolate gets signal edge events ~300us after they ocurred, the main isolate after ~1000us)
- works without flutter-pi now too
- tested & working on ARM32, but should work on other 32-bit and 64-bit linux platforms too (untested though)

# flutter_gpiod

A dart package for GPIO access on linux / Android (*root required*) using the linux GPIO character-device interface.

## Getting Started

Then, you can retrieve the list of GPIO chips attached to
your system using [FlutterGpiod.chips]. Each chip has a name,
label and a number of GPIO lines associated with it.
```dart
final chips = FlutterGpiod.instance.chips;

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
// Get the chip with label 'pinctrl-bcm2835'.
// This is the main Raspberry Pi GPIO chip.
final chip = FlutterGpiod.instance.chips.singleWhere((chip) => chip.label == 'pinctrl-bcm2835');

// Get line 22 of the 'pinctrl-bcm2835' GPIO chip.
// This is the BCM 22 pin of the Raspberry Pi.
final line = chip.lines[22];

print("line info: ${line.info}")
```

To control a line (to read or write values or to listen for edges),
you need to request it using [GpioLine.requestInput] or [GpioLine.requestOutput].
```dart
final chip = FlutterGpiod.instance.chips.singleWhere((chip) => chip.label == 'pinctrl-bcm2835');
final line = chip.lines[22];

// request it as input.
line.requestInput();
print("line value: ${line.getValue()}");
line.release();

// now we're requesting it as output.
line.requestOutput(initialValue: true);
line.setValue(false);
line.release();

// request it as input again, but this time we're also listening
// for edges; both in this case.
line.requestInput(triggers: {SignalEdge.falling, SignalEdge.rising});

print("line value: ${line.getValue()}");

// line.onEvent will not emit any events if no triggers
// are requested for the line.
// this will run forever
await for (final event in line.onEvent) {
  print("got GPIO line signal event: $event");
}

line.release();
```
