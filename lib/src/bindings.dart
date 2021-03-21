library bindings;

// ignore_for_file: non_constant_identifier_names, camel_case_types, unnecessary_brace_in_string_interps, unused_element

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;

import 'bindings/epoll_event.dart';
export 'bindings/epoll_event.dart';
import 'bindings/libc32_bindings.g.dart' show LibCInternal32;
import 'bindings/libc64_bindings.g.dart' show LibCInternal64;

part 'bindings/libc_constants.g.dart';
part 'bindings/gpio_bindings.g.dart';

typedef _c_ioctl_pointer_32 = ffi.Int32 Function(ffi.Int32 __fd, ffi.Uint32 __request, ffi.Pointer<ffi.Void> argp);

typedef _c_ioctl_pointer_64 = ffi.Int32 Function(ffi.Int32 __fd, ffi.Uint64 __request, ffi.Pointer<ffi.Void> argp);

typedef _dart_ioctl_pointer = int Function(int __fd, int __request, ffi.Pointer<ffi.Void> argp);

typedef _c_errno_location = ffi.Pointer<ffi.Int32> Function();

typedef _dart_errno_location = ffi.Pointer<ffi.Int32> Function();

abstract class LibCBase {
  int ioctl(int __fd, int __request);
  int ioctlPointer(int __fd, int __request, ffi.Pointer argp);
  int epoll_create(int __size);
  int epoll_create1(int __flags);
  int epoll_ctl(int __epfd, int __op, int __fd, ffi.Pointer<epoll_event> __event);
  int epoll_wait(int __epfd, ffi.Pointer<epoll_event> __events, int __maxevents, int __timeout);
  int open(ffi.Pointer<ffi.Int8> __file, int __oflag);
  int close(int __fd);
  int read(int __fd, ffi.Pointer<ffi.Void> __buf, int __nbytes);
}

extension TryLookup on ffi.DynamicLibrary {
  T tryLookupFunction<T>(T doLookup()) {
    try {
      return doLookup();
    } on ArgumentError {
      return null;
    }
  }

  ffi.Pointer<T> tryLookup<T extends ffi.NativeType>(String symbolName) {
    try {
      return this.lookup<T>(symbolName);
    } on ArgumentError {
      return null;
    }
  }
}

class LibC32 extends LibCInternal32 implements LibCBase {
  LibC32(this._dylib) : super(_dylib);

  final ffi.DynamicLibrary _dylib;

  _dart_ioctl_pointer _ioctlPointer;
  @override
  int ioctlPointer(int __fd, int __request, ffi.Pointer argp) {
    _ioctlPointer ??= _dylib.lookupFunction<_c_ioctl_pointer_32, _dart_ioctl_pointer>('ioctl');
    return _ioctlPointer(__fd, __request, argp.cast<ffi.Void>());
  }
}

class LibC64 extends LibCInternal64 implements LibCBase {
  LibC64(this._dylib) : super(_dylib);

  final ffi.DynamicLibrary _dylib;

  @override
  int ioctlPointer(int __fd, int __request, ffi.Pointer argp) {
    _ioctlPointer ??= _dylib.lookupFunction<_c_ioctl_pointer_64, _dart_ioctl_pointer>('ioctl');
    return _ioctlPointer(__fd, __request, argp.cast<ffi.Void>());
  }

  _dart_ioctl_pointer _ioctlPointer;
}

class LibC implements LibCBase {
  LibC._internal(this._dylib, this._native);

  factory LibC(ffi.DynamicLibrary dylib) {
    LibCBase _native;

    if (ffi.sizeOf<ffi.Pointer>() == 8) {
      _native = LibC64(dylib);
    } else {
      _native = LibC32(dylib);
    }

    return LibC._internal(dylib, _native);
  }

  final ffi.DynamicLibrary _dylib;
  final LibCBase _native;

  @override
  int close(int __fd) => _native.close(__fd);

  @override
  int epoll_create(int __size) => _native.epoll_create(__size);

  @override
  int epoll_create1(int __flags) => _native.epoll_create1(__flags);

  @override
  int epoll_ctl(int __epfd, int __op, int __fd, ffi.Pointer<epoll_event> __event) => _native.epoll_ctl(__epfd, __op, __fd, __event);

  @override
  int epoll_wait(int __epfd, ffi.Pointer<epoll_event> __events, int __maxevents, int __timeout) => _native.epoll_wait(__epfd, __events, __maxevents, __timeout);

  @override
  int ioctl(int __fd, int __request) => _native.ioctl(__fd, __request);

  @override
  int ioctlPointer(int __fd, int __request, ffi.Pointer<ffi.NativeType> argp) => _native.ioctlPointer(__fd, __request, argp);

  @override
  int open(ffi.Pointer<ffi.Int8> __file, int __oflag) => _native.open(__file, __oflag);

  @override
  int read(int __fd, ffi.Pointer<ffi.Void> __buf, int __nbytes) => _native.read(__fd, __buf, __nbytes);

  _dart_errno_location __errnoLocation;
  ffi.Pointer<ffi.Int32> get _errnoLocation {
    if (__errnoLocation == null) {
      __errnoLocation = _dylib.tryLookupFunction(() => _dylib.lookupFunction<_c_errno_location, _dart_errno_location>("__errno_location"));

      if (__errnoLocation == null) {
        __errnoLocation = _dylib.tryLookupFunction(() => _dylib.lookupFunction<_c_errno_location, _dart_errno_location>("__errno"));
      }

      if (__errnoLocation == null) {
        __errnoLocation = _dylib.tryLookupFunction(() => _dylib.lookupFunction<_c_errno_location, _dart_errno_location>("_dl_errno"));
      }

      if (__errnoLocation == null) {
        __errnoLocation = _dylib.tryLookupFunction(() => _dylib.lookupFunction<_c_errno_location, _dart_errno_location>("__libc_errno"));
      }

      if (__errnoLocation == null) {
        final errnoPtr = _dylib.tryLookup<ffi.Int32>("errno");
        if (errnoPtr != null) {
          __errnoLocation = () => errnoPtr;
        }
      }
    }

    return __errnoLocation != null ? __errnoLocation() : null;
  }

  int get errno {
    return _errnoLocation?.value;
  }

  set errno(int value) {
    _errnoLocation?.value = value;
  }
}

List<T> listFromArrayHelper<T>(int length, T getElement(int index)) {
  return List.generate(length, getElement, growable: false);
}

String stringFromInlineArray(int maxLength, int getElement(int index), {Encoding codec = const Utf8Codec(allowMalformed: true)}) {
  final list = listFromArrayHelper(maxLength, getElement);
  final indexOfZero = list.indexOf(0);
  final length = indexOfZero == -1 ? maxLength : indexOfZero;

  return codec.decode(list.sublist(0, length));
}

void writeStringToArrayHelper(String str, int length, void setElement(int index, int value), {Encoding codec = const Utf8Codec(allowMalformed: true)}) {
  final untruncatedBytes = List.of(codec.encode(str))..addAll(List.filled(length, 0));

  untruncatedBytes.take(length).toList().asMap().forEach(setElement);
}

class LinuxError extends OSError {
  LinuxError._private([String message, int errno = OSError.noErrorCode]) : super(message ?? "", errno);

  factory LinuxError([String description, String method, int errno]) {
    final hasErrno = errno != null && errno != OSError.noErrorCode;
    final errorMessage = hasErrno ? _errnoToString[errno] ?? "($errno)" : null;

    var msg = "";

    if (description != null) {
      msg += "$description.";
    }

    if (method != null) {
      if (description != null) msg += ", ";
      msg += "$method";
    }

    if (errorMessage != null) {
      if (method != null)
        msg += ": ";
      else if (description != null) msg += " ";
      msg += "$errorMessage";
    }

    return LinuxError._private(msg, errno);
  }

  @override
  String toString() {
    return message;
  }

  static const _errnoToString = <int, String>{
    1: "Operation not permitted",
    2: "No such file or directory",
    3: "No such process",
    4: "Interrupted system call",
    5: "I/O error",
    6: "No such device or address",
    7: "Argument list too long",
    8: "Exec format error",
    9: "Bad file number",
    10: "No child processes",
    11: "Operation would block",
    12: "Out of memory",
    13: "Permission denied",
    14: "Bad address",
    15: "Block device required",
    16: "Device or resource busy",
    17: "File exists",
    18: "Cross-device link",
    19: "No such device",
    20: "Not a directory",
    21: "Is a directory",
    22: "Invalid argument",
    23: "File table overflow",
    24: "Too many open files",
    25: "Not a typewriter",
    26: "Text file busy",
    27: "File too large",
    28: "No space left on device",
    29: "Illegal seek",
    30: "Read-only file system",
    31: "Too many links",
    32: "Broken pipe",
    33: "Math argument out of domain of func",
    34: "Math result not representable",
    35: "Resource deadlock would occur",
    36: "File name too long",
    37: "No record locks available",
    38: "Invalid system call number",
    39: "Directory not empty",
    40: "Too many symbolic links encountered",
    41: "Operation would block",
    42: "No message of desired type",
    43: "Identifier removed",
    44: "Channel number out of range",
    45: "Level 2 not synchronized",
    46: "Level 3 halted",
    47: "Level 3 reset",
    48: "Link number out of range",
    49: "Protocol driver not attached",
    50: "No CSI structure available",
    51: "Level 2 halted",
    52: "Invalid exchange",
    53: "Invalid request descriptor",
    54: "Exchange full",
    55: "No anode",
    56: "Invalid request code",
    57: "Invalid slot",
    59: "Bad font file format",
    60: "Device not a stream",
    61: "No data available",
    62: "Timer expired",
    63: "Out of streams resources",
    64: "Machine is not on the network",
    65: "Package not installed",
    66: "Object is remote",
    67: "Link has been severed",
    68: "Advertise error",
    69: "Srmount error",
    70: "Communication error on send",
    71: "Protocol error",
    72: "Multihop attempted",
    73: "RFS specific error",
    74: "Not a data message",
    75: "Value too large for defined data type",
    76: "Name not unique on network",
    77: "File descriptor in bad state",
    78: "Remote address changed",
    79: "Can not access a needed shared library",
    80: "Accessing a corrupted shared library",
    81: ".lib section in a.out corrupted",
    82: "Attempting to link in too many shared libraries",
    83: "Cannot exec a shared library directly",
    84: "Illegal byte sequence",
    85: "Interrupted system call should be restarted",
    86: "Streams pipe error",
    87: "Too many users",
    88: "Socket operation on non-socket",
    89: "Destination address required",
    90: "Message too long",
    91: "Protocol wrong type for socket",
    92: "Protocol not available",
    93: "Protocol not supported",
    94: "Socket type not supported",
    95: "Operation not supported on transport endpoint",
    96: "Protocol family not supported",
    97: "Address family not supported by protocol",
    98: "Address already in use",
    99: "Cannot assign requested address",
    100: "Network is down",
    101: "Network is unreachable",
    102: "Network dropped connection because of reset",
    103: "Software caused connection abort",
    104: "Connection reset by peer",
    105: "No buffer space available",
    106: "Transport endpoint is already connected",
    107: "Transport endpoint is not connected",
    108: "Cannot send after transport endpoint shutdown",
    109: "Too many references: cannot splice",
    110: "Connection timed out",
    111: "Connection refused",
    112: "Host is down",
    113: "No route to host",
    114: "Operation already in progress",
    115: "Operation now in progress",
    116: "Stale file handle",
    117: "Structure needs cleaning",
    118: "Not a XENIX named type file",
    119: "No XENIX semaphores available",
    120: "Is a named type file",
    121: "Remote I/O error",
    122: "Quota exceeded",
    123: "No medium found",
    124: "Wrong medium type",
    125: "Operation Canceled",
    126: "Required key not available",
    127: "Key has expired",
    128: "Key has been revoked",
    129: "Key was rejected by service",
    130: "Owner died",
    131: "State not recoverable",
    132: "Operation not possible due to RF-kill",
    133: "Memory page has hardware error",
  };
}
