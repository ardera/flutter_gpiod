import 'dart:async';

import 'package:mutex/mutex.dart';
import 'package:meta/meta.dart';
import 'package:async/async.dart';

import 'package:flutter/services.dart'
    show EventChannel, MethodChannel, StandardMethodCodec;

/// The direction of a gpiod line.
enum LineDirection { input, output }

/// The way high voltage / low voltage should be written
/// to the line.
enum OutputMode { pushPull, openDrain, openSource }

/// Whether there should be pull-up or -down
/// resistors connected to the line.
enum Bias { disable, pullUp, pullDown }

/// Whether the line should be high voltage when
/// it's active or low voltage.
enum ActiveState { high, low }

/// It's a rising edge when the voltage goes from low to high,
/// falling from high to low.
enum SignalEdge { rising, falling }

@immutable
class _GlobalSignalEvent {
  final int lineHandle;
  final SignalEvent signalEvent;

  const _GlobalSignalEvent(this.lineHandle, this.signalEvent);

  factory _GlobalSignalEvent._fromList(List list) {
    return _GlobalSignalEvent(
        list[0] as int, SignalEvent._fromList(list.sublist(1)));
  }

  String toString() {
    return "_GpiodEvent(lineHandle: $lineHandle, lineEvent: $signalEvent)";
  }
}

/// An event that can ocurr on a line when
/// you are listening on it.
///
/// Contains the edge that triggered the event,
/// and the time when this event ocurred.
/// (which is given by the kernel)
@immutable
class SignalEvent {
  /// The edge that was detected on the [GpioLine].
  final SignalEdge edge;

  /// The time this edge ocurred, given by the
  /// linux kernel.
  final DateTime time;

  const SignalEvent._(this.edge, this.time);

  factory SignalEvent._fromList(List list) {
    final edge = SignalEdge.values.firstWhere((v) => v.toString() == list[0]);
    final s = list[1][0] as int;
    final ns = list[1][1] as int;

    final time =
        DateTime.fromMicrosecondsSinceEpoch(s * 1000000 + (ns / 1000).round());

    return SignalEvent._(edge, time);
  }

  String toString() {
    final edgeStr = edge == SignalEdge.falling ? "falling" : "rising";
    return "SignalEvent(edge: $edgeStr, time: $time)";
  }
}

/// Provides raw access to the platform-side methods.
@immutable
class _FlutterGpiodPlatformSide {
  static const _methodChannel =
      MethodChannel("plugins.flutter.io/gpiod", StandardMethodCodec());
  static const _eventChannel = EventChannel("plugins.flutter.io/gpiod_events");

  static Stream<_GlobalSignalEvent> receiveBroadcastStream() {
    return _eventChannel
        .receiveBroadcastStream()
        .map((arg) => _GlobalSignalEvent._fromList(arg as List));
  }

  static Future<int> getNumChips() async {
    return (await _methodChannel.invokeMethod("getNumChips", null)) as int;
  }

  static Future<Map<String, dynamic>> getChipDetails(int chipIndex) async {
    return await _methodChannel.invokeMapMethod("getChipDetails", chipIndex);
  }

  static Future<int> getLineHandle(int chipIndex, int lineIndex) async {
    return (await _methodChannel
        .invokeMethod("getLineHandle", <int>[chipIndex, lineIndex])) as int;
  }

  static Future<LineInfo> getLineInfo(int lineHandle) async {
    return LineInfo._fromMap(await _methodChannel
        .invokeMapMethod<String, dynamic>("getLineDetails", lineHandle));
  }

  static Future<void> requestLine(
      {int lineHandle,
      String consumer,
      LineDirection direction,
      OutputMode outputMode,
      Bias bias,
      ActiveState activeState,
      Set<SignalEdge> triggers,
      bool initialValue}) async {
    await _methodChannel.invokeMethod("requestLine", {
      'lineHandle': lineHandle,
      'consumer': consumer,
      'direction': direction.toString(),
      'outputMode': outputMode?.toString(),
      'bias': bias?.toString(),
      'activeState': activeState.toString(),
      'triggers': triggers?.map((t) => t.toString())?.toList(),
      'initialValue': initialValue
    });
  }

  static Future<void> releaseLine(int lineHandle) async {
    await _methodChannel.invokeMethod("releaseLine", lineHandle);
  }

  static Future<void> reconfigureLine(
      {int lineHandle,
      LineDirection direction,
      OutputMode outputMode,
      Bias bias,
      ActiveState activeState,
      bool initialValue}) async {
    await _methodChannel.invokeMethod("reconfigureLine", {
      'lineHandle': lineHandle,
      'direction': direction.toString(),
      'outputMode': outputMode?.toString(),
      'bias': bias?.toString(),
      'activeState': activeState.toString(),
      'initialValue': initialValue
    });
  }

  static Future<bool> getLineValue(int lineHandle) async {
    return (await _methodChannel.invokeMethod("getLineValue", lineHandle))
        as bool;
  }

  static Future<void> setLineValue(int lineHandle, bool value) async {
    await _methodChannel.invokeMethod("setLineValue", [lineHandle, value]);
  }

  static Future<bool> supportsBias() async {
    return (await _methodChannel.invokeMethod("supportsBias")) as bool;
  }

  static Future<bool> supportsLineReconfiguration() async {
    return (await _methodChannel.invokeMethod("supportsLineReconfiguration"))
        as bool;
  }
}

/// Global interface to libgpiod.
///
/// Starting-point for querying gpio chips or lines,
/// and finding the line you want to control.
class FlutterGpiod {
  FlutterGpiod._internal(
      this.chips, this.supportsBias, this.supportsLineReconfiguration);

  static FlutterGpiod _instance;

  /// The list of GPIO chips attached to this system.
  final List<GpioChip> chips;

  /// Whether setting and getting GPIO line bias is supported.
  ///
  /// See [GpioLine.request] and [GpioLine.reconfigure].
  final bool supportsBias;

  /// Whether GPIO line reconfiguration is supported.
  ///
  /// See [GpioLine.reconfigure].
  final bool supportsLineReconfiguration;

  Stream<_GlobalSignalEvent> __onGlobalSignalEvent;

  /// Gets the global instance of [FlutterGpiod].
  ///
  /// If none exists, one will be constructed.
  static Future<FlutterGpiod> getInstance() async {
    if (_instance == null) {
      final List<GpioChip> chips = List.unmodifiable(await Future.wait(
          List.generate(await _FlutterGpiodPlatformSide.getNumChips(),
              (i) => GpioChip._fromIndex(i))));
      final bias = await _FlutterGpiodPlatformSide.supportsBias();
      final reconfig =
          await _FlutterGpiodPlatformSide.supportsLineReconfiguration();

      _instance = FlutterGpiod._internal(chips, bias, reconfig);
    }

    return _instance;
  }

  Stream<_GlobalSignalEvent> get _onGlobalSignalEvent {
    __onGlobalSignalEvent ??=
        _FlutterGpiodPlatformSide.receiveBroadcastStream();
    return __onGlobalSignalEvent;
  }

  Stream<SignalEvent> _onSignalEvent(int lineHandle) {
    return _onGlobalSignalEvent
        .where((e) => e.lineHandle == lineHandle)
        .map((e) => e.signalEvent);
  }
}

/// A single gpio chip providing access to
/// some number of gpio lines / pins.
@immutable
class GpioChip {
  /// The index of the GPIO chip in the [FlutterGpiod.chips] list,
  /// and at the same time, the numerical suffix of [name].
  final int index;

  /// The name of this GPIO chip.
  ///
  /// This is the filename of the underlying GPIO device, so
  /// for example `gpiochip0` or `gpiochip1`.
  final String name;

  /// The label of this GPIO chip.
  ///
  /// This is the hardware label of the underlying GPIO device.
  /// The main GPIO chip of the Raspberry Pi 4 has the label
  /// `brcm2835-pinctrl` for example.
  final String label;

  final int _numLines;

  /// The GPIO lines (pins) associated with this chip.
  final List<GpioLine> lines;

  GpioChip._(this.index, this.name, this.label, this._numLines, this.lines);

  static Future<GpioChip> _fromIndex(int chipIndex) async {
    final details = await _FlutterGpiodPlatformSide.getChipDetails(chipIndex);

    final lines = await Future.wait(List.generate(
        details['numLines'],
        (i) async => await GpioLine._fromHandle(
            await _FlutterGpiodPlatformSide.getLineHandle(chipIndex, i))));

    return GpioChip._(chipIndex, details['name'], details['label'],
        details['numLines'], List.unmodifiable(lines));
  }

  @override
  String toString() {
    return "GpiodChip(index: $index, name: '$name', label: '$label', numLines: $_numLines)";
  }
}

/// Info about a GPIO line. Also contains
/// the line configuration.
@immutable
class LineInfo {
  /// The name (determined by the driver or device tree) of this line.
  ///
  /// Can be null, is limited and truncated to 32 characters.
  ///
  /// For example, `PWR_LED_OFF` is the name of a GPIO line on
  /// Raspberry Pi.
  final String name;

  /// A label given to the line by the application currently using this
  /// line, ideally describing what the line is used for right now.
  ///
  /// Can be null, is limited and truncated to 32 characters.
  final String consumer;

  /// Whether the line is currently used by any application.
  final bool isUsed;

  /// Whether the line is requested / owned by _this_ application.
  final bool isRequested;

  /// Whether the line is free to be requested by any application.
  final bool isFree;

  /// The direction of the line.
  final LineDirection direction;

  /// The output mode of the line.
  final OutputMode outputMode;

  /// The bias of the line.
  final Bias bias;

  /// The active state of the GPIO line.
  ///
  /// Defines the mapping of active/inactive to low/high voltage.
  /// [ActiveState.low] is the counter-intuitive one,
  /// which maps active (i.e. `line.setValue(true)`) to low voltage and inactive to high voltage.
  final ActiveState activeState;

  const LineInfo._(
      {this.name,
      this.consumer,
      this.direction,
      this.outputMode,
      this.bias,
      this.activeState,
      this.isUsed,
      this.isRequested,
      this.isFree});

  factory LineInfo._fromMap(Map<String, dynamic> map) {
    return LineInfo._(
        name: map['name'] as String,
        consumer: map['consumer'] as String,
        direction: LineDirection.values
            .firstWhere((v) => v.toString() == map['direction']),
        outputMode: OutputMode.values.firstWhere(
            (v) => v.toString() == map['outputMode'],
            orElse: () => null),
        bias: Bias.values
            .firstWhere((v) => v.toString() == map['bias'], orElse: () => null),
        activeState: ActiveState.values
            .firstWhere((v) => v.toString() == map['activeState']),
        isUsed: map['isUsed'] as bool,
        isRequested: map['isRequested'] as bool,
        isFree: map['isFree'] as bool);
  }

  String toString() {
    final params = <String>[];

    if (name != null) {
      params.add("name: '$name'");
    }

    if (consumer != null) {
      params.add("consumer: '$consumer'");
    }

    if (direction == LineDirection.input) {
      params.add("direction:  input");
    } else {
      params.add("direction: output");

      if (outputMode == OutputMode.openDrain) {
        params.add("outputMode:  openDrain");
      } else if (outputMode == OutputMode.openSource) {
        params.add("outputMode: openSource");
      }
    }

    if (bias == Bias.disable) {
      params.add("bias:  disable");
    } else if (bias == Bias.pullDown) {
      params.add("bias: pullDown");
    } else if (bias == Bias.pullUp) {
      params.add("bias:   pullUp");
    }

    if (activeState == ActiveState.low) {
      params.add("activeState: low");
    }

    params.add("isUsed: $isUsed");
    params.add("isRequested: $isRequested");
    params.add("isFree: $isFree");

    return "LineInfo(${params.join(", ")})";
  }
}

/// Provides access to a single GPIO line / pin.
///
/// Basically has 3 states that define the methods you can call:
///   `unrequested`, `requested input`, `requested output`
///
/// Example usage of [GpioLine]:
/// ```dart
/// import 'package:flutter_gpiod/flutter_gpiod.dart';
///
/// final gpio = await FlutterGpiod.getInstance()
///
/// // get the line with index 22 from the first chip
/// final line = gpio.chips.singleWhere(
///   (chip) => chip.label == 'pinctrl-bcm2835'
/// );
/// print("pinctrl-bcm2835, line 22: $(await line.info)");
///
/// // request is as output and initialize it with false
/// await line.requestOutput(
///   consumer: "flutter_gpiod output test",
///   initialValue: false
/// ));
///
/// // set the line active
/// await line.setValue(true);
///
/// await Future.delayed(Duration(milliseconds: 500));
///
/// // set the line inactive again
/// await line.setValue(false);
///
/// await line.release();
///
/// // request the line as input, and listen for both edges
/// // we don't use `line.reconfigure` because that doesn't
/// // allow us to specify triggers.
/// await line.requestInput(
///   consumer: "flutter_gpiod input test",
///   triggers: const {SignalEdge.rising, SignalEdge.falling}
/// ));
///
/// // print line events for eternity
/// await for (final event in line.onEvent) {
///   print("gpio line signal event: $event");
/// }
///
/// // await line.release();
/// ```
/// Notice that access to the methods in GpioLine is synchronized.
///
/// This will throw an error:
/// ```dart
/// final gpio = await FlutterGpiod.getInstance();
///
/// final line = gpio.chips.singleWhere(
///   (chip) => chip.label == 'pinctrl-bcm2835'
/// );
///
/// line.requestInput() // notice the missing await
///
/// print("is line requested? ${line.requested}"); // this will throw the error.
/// // The line ownership is undefined until the Future returned by line.requestInput() finishes.
/// // Because this code doesn't wait until the returned Future completes,
/// //   the request may still be running when `line.requested` is queried.
/// ```
class GpioLine {
  GpioLine._internal(this._lineHandle, this._requested, this._info,
      this._triggers, this._value);

  final _mutex = ReadWriteMutex();
  final int _lineHandle;
  bool _requested;
  LineInfo _info;
  Set<SignalEdge> _triggers;
  bool _value;

  void _assertNotWriteLocked() {
    if (_mutex.isWriteLocked) {
      throw StateError("Action can't finish synchronously because "
          "of an ongoing operation that can change the state "
          "of the GPIO line.");
    }
  }

  Future<T> _synchronizedRead<T>(FutureOr<T> f()) {
    return _mutex
        .acquireRead()
        .then((_) => f())
        .whenComplete(() => _mutex.release());
  }

  Future<T> _synchronizedWrite<T>(FutureOr<T> f()) {
    return _mutex
        .acquireWrite()
        .then((_) => f())
        .whenComplete(() => _mutex.release());
  }

  static Future<GpioLine> _fromHandle(int lineHandle) async {
    final info = await _FlutterGpiodPlatformSide.getLineInfo(lineHandle);

    if (info.isRequested) {
      return GpioLine._internal(lineHandle, true, info, const {},
          await _FlutterGpiodPlatformSide.getLineValue(lineHandle));
    } else {
      return GpioLine._internal(lineHandle, false, null, const {}, null);
    }
  }

  /// Returns the line info for this line.
  ///
  /// Will return a [LineInfo] synchronously when `requested == true`
  /// and no request / reconfiguration / release is going on right now.
  /// Otherwise, returns a `Future<LineInfo>`.
  FutureOr<LineInfo> get info {
    if (_mutex.isWriteLocked == false && _info != null) {
      return _info;
    }

    return _synchronizedRead(
        () => _FlutterGpiodPlatformSide.getLineInfo(_lineHandle));
  }

  /// Provides synchronous access to [info].
  ///
  /// Throws a [StateError] when synchronous access is not possible.
  /// Synchronous access is possible when `requested == true` and
  /// no request / reconfiguration / release is going on right now.
  ///
  /// When possible, [info] will return synchronously,
  /// but you have to cast it to `LineInfo` every time you want to use it,
  /// which is kinda annoying.
  /// This method does the casting for you.
  LineInfo get infoSync {
    _assertNotWriteLocked();

    if (!requested) {
      throw StateError("Can't get line info because line "
          "is not requested.");
    }

    return _info;
  }

  /// Returns a proxy providing strictly asynchronous access to the above getters.
  ///
  /// You can't call [Future.then] or [Future.whenComplete] on the [FutureOr] values
  /// returned by [info]. This method constructs a [Future] out of the [FutureOr]
  /// returned by [info]. (regardless of the actual type of the [FutureOr])
  Future<LineInfo> get infoAsync {
    return _synchronizedRead(
        () => _FlutterGpiodPlatformSide.getLineInfo(_lineHandle));
  }

  /// Whether this line is requested (owned by you) right now.
  ///
  /// `requested == true` means that you own the line,
  /// and can do things with it.
  ///
  /// If `requested == false` then you can't do more
  /// than retrieve the line info using the [info] property.
  bool get requested {
    _assertNotWriteLocked();
    return _requested;
  }

  /// The signal edges that this line is listening on right now,
  /// or equivalently, the signal edges that will trigger a [SignalEvent]
  /// that can be retrieved by listening on [GpioLine.onEvent].
  ///
  /// The triggers can be specified when requesting the line with [requestInput], but
  /// can __not__ be changed using [reconfigureInput] when the line is already requested.
  ///
  /// You can, of course, release the line and re-request it with
  /// different triggers if you need to, though.
  Set<SignalEdge> get triggers {
    _assertNotWriteLocked();
    return Set.of(_triggers);
  }

  void _checkSupportsBiasValue(Bias bias) {
    if ((bias != null) && !FlutterGpiod._instance.supportsBias) {
      throw UnsupportedError("Line bias is not supported on this platform."
          "Expected `bias` to be null.");
    }
  }

  /// Requests ownership of a GPIO line with the given configuration.
  ///
  /// If [FlutterGpiod.supportsBias] is false, [bias] must be `null`,
  /// otherwise a [UnsupportedError] will be thrown.
  ///
  /// Only a free line can be requested.
  ///
  /// The ownership status in undefined until the [Future]
  /// returned by [request] completes.
  Future<void> requestInput(
      {String consumer,
      Bias bias,
      ActiveState activeState = ActiveState.high,
      Set<SignalEdge> triggers = const {}}) {
    ArgumentError.checkNotNull(activeState, "activeState");
    ArgumentError.checkNotNull(triggers, "triggers");
    _checkSupportsBiasValue(bias);

    // we need to lock both info and ownership.
    return _synchronizedWrite(() async {
      if (_requested) {
        throw StateError("Can't request line because it is already requested.");
      }

      await _FlutterGpiodPlatformSide.requestLine(
          lineHandle: _lineHandle,
          consumer: consumer,
          direction: LineDirection.input,
          bias: bias,
          activeState: activeState,
          triggers: triggers);

      _info = await _FlutterGpiodPlatformSide.getLineInfo(_lineHandle);
      _requested = true;
    });
  }

  Future<void> requestOutput(
      {String consumer,
      OutputMode outputMode = OutputMode.pushPull,
      Bias bias,
      ActiveState activeState = ActiveState.high,
      @required bool initialValue}) async {
    ArgumentError.checkNotNull(outputMode, "outputMode");
    ArgumentError.checkNotNull(activeState, "activeState");
    ArgumentError.checkNotNull(initialValue, "initialValue");
    _checkSupportsBiasValue(bias);

    // we need to lock both info and ownership.
    return _synchronizedWrite(() async {
      if (_requested) {
        throw StateError("Can't request line because it is already requested.");
      }

      await _FlutterGpiodPlatformSide.requestLine(
          lineHandle: _lineHandle,
          consumer: consumer,
          direction: LineDirection.output,
          outputMode: outputMode,
          bias: bias,
          activeState: activeState,
          initialValue: initialValue);

      _info = await _FlutterGpiodPlatformSide.getLineInfo(_lineHandle);
      _value = initialValue;
      _requested = true;
    });
  }

  void _checkSupportsLineReconfiguration() {
    if (!FlutterGpiod._instance.supportsLineReconfiguration) {
      throw UnsupportedError(
          "Can't reconfigure line because that's not supported by "
          "the underlying version of libgpiod. "
          "You need to check `FlutterGpiod.supportsLineReconfiguration` "
          "to make sure you can reconfigure.");
    }
  }

  /// Reconfigures the line as input with the given configuration.
  ///
  /// If [FlutterGpiod.supportsBias] is false, [bias] must be `null`,
  /// otherwise a [UnsupportedError] will be thrown.
  ///
  /// This will throw a [UnsupportedError] if
  /// [FlutterGpiod.supportsLineReconfiguration] is false.
  ///
  /// You can't specify triggers here because of platform
  /// limitations.
  Future<void> reconfigureInput(
      {Bias bias, ActiveState activeState = ActiveState.high}) {
    ArgumentError.checkNotNull(activeState, "activeState");
    _checkSupportsBiasValue(bias);
    _checkSupportsLineReconfiguration();

    // we only change the info, not the ownership
    return _synchronizedWrite(() async {
      _info = null;
      _value = null;

      if (!_requested) {
        throw StateError(
            "Can't reconfigured line because it is not requested.");
      }

      await _FlutterGpiodPlatformSide.reconfigureLine(
          lineHandle: _lineHandle,
          direction: LineDirection.input,
          bias: bias,
          activeState: activeState);

      _info = await _FlutterGpiodPlatformSide.getLineInfo(_lineHandle);
    });
  }

  /// Reconfigures the line as output with the given configuration.
  ///
  /// If [FlutterGpiod.supportsBias] is false, [bias] must be `null`,
  /// otherwise a [UnsupportedError] will be thrown.
  ///
  /// This will throw a [UnsupportedError] if
  /// [FlutterGpiod.supportsLineReconfiguration] is false.
  Future<void> reconfigureOutput(
      {OutputMode outputMode = OutputMode.pushPull,
      Bias bias,
      ActiveState activeState = ActiveState.high,
      @required bool initialValue}) {
    ArgumentError.checkNotNull(outputMode, "outputMode");
    _checkSupportsBiasValue(bias);
    ArgumentError.checkNotNull(activeState, "activeState");
    ArgumentError.checkNotNull(initialValue, "initialValue");
    _checkSupportsLineReconfiguration();

    return _synchronizedWrite(() async {
      _info = null;
      _value = null;

      if (!_requested) {
        throw StateError(
            "Can't reconfigured line because it is not requested.");
      }

      await _FlutterGpiodPlatformSide.reconfigureLine(
          lineHandle: _lineHandle,
          direction: LineDirection.output,
          outputMode: outputMode,
          bias: bias,
          activeState: activeState,
          initialValue: initialValue);

      _value = initialValue;
      _info = await _FlutterGpiodPlatformSide.getLineInfo(_lineHandle);
    });
  }

  /// Releases the line, so you don't own it anymore.
  ///
  /// The lines ownership is undefined until the Future
  /// returned by [release] completes.
  Future<void> release() {
    return _synchronizedWrite(() async {
      if (!_requested) {
        throw StateError("Can't release line because it is not requested.");
      }

      await _FlutterGpiodPlatformSide.releaseLine(_lineHandle);

      _requested = false;
      _info = null;
      _triggers = const {};
      _value = null;
    });
  }

  /// Sets the value of the line to active (true) or inactive (false).
  ///
  /// Throws a [StateError] if the line is not requested as output.
  Future<void> setValue(bool value) {
    ArgumentError.checkNotNull(value, "value");

    return _synchronizedRead(() async {
      if (!_requested || _info.direction != LineDirection.output) {
        throw StateError(
            "Can't set line value because line is not configured as output.");
      }

      if (_value == value) return;

      await _FlutterGpiodPlatformSide.setLineValue(_lineHandle, value);

      _value = value;
    });
  }

  /// Reads the value of the line (active / inactive)
  ///
  /// Throws a [StateError] if the line is not requested.
  ///
  /// If the line is in output mode, the last written value
  /// using [setValue] will be returned synchronously.
  /// If [setValue] was never called, the `initialValue`
  /// given to [request] or [release] will be returned.
  ///
  /// If `direction == LineDirection.input` this will obtain a
  /// fresh value from the platform side.
  FutureOr<bool> getValue() {
    if (_mutex.isWriteLocked) {
      // If it is locked, we need to synchronize the access.
      return _synchronizedRead(() {
        if (_requested == false) {
          throw StateError(
              "Can't get line value because line is not requested.");
        }

        if (_info.direction == LineDirection.input) {
          return _FlutterGpiodPlatformSide.getLineValue(_lineHandle);
        } else {
          return _value;
        }
      });
    } else {
      if (_requested == false) {
        throw StateError("Can't get line value because line is not requested.");
      }

      if (_info.direction == LineDirection.output) {
        return _value;
      } else {
        return _synchronizedRead(
            () => _FlutterGpiodPlatformSide.getLineValue(_lineHandle));
      }
    }
  }

  /// Gets a broadcast stream of [SignalEvent]s for this line.
  ///
  /// Note that platforms can and do emit events with same
  /// [SignalEvent.edge] in sequence, with no event
  /// with different edge between.
  ///
  /// So, it often happens that platforms emit events
  /// like this: `rising`, `rising`, `rising`, `falling`, `rising`,
  /// even though that doesn't seem to make any sense
  /// at first glance.
  Stream<SignalEvent> get onEvent {
    final completer = StreamCompleter<SignalEvent>();

    _synchronizedRead(() => FlutterGpiod._instance._onSignalEvent(_lineHandle))
        .then((stream) => completer.setSourceStream(stream),
            onError: (error, stackTrace) =>
                completer.setError(error, stackTrace));

    return completer.stream;
  }

  /// Broadcast stream of signal edges.
  ///
  /// Basically the [onEvent] stream without the timestamp.
  Stream<SignalEdge> get onEdge => onEvent.map((e) => e.edge);

  String toString() {
    final infoStr = _requested ? ", info: $infoSync" : "";
    return "GpioLine(requested: $_requested$infoStr)";
  }
}
