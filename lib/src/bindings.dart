library bindings;

// ignore_for_file: non_constant_identifier_names, camel_case_types, unnecessary_brace_in_string_interps, unused_element

import 'dart:convert';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;

import 'bindings/epoll_event.dart';
export 'bindings/epoll_event.dart';
import 'bindings/libc32_bindings.g.dart' show LibCInternal32;
import 'bindings/libc64_bindings.g.dart' show LibCInternal64;

part 'bindings/libc_constants.g.dart';
part 'bindings/gpio_bindings.g.dart';

typedef _c_ioctl_pointer_32 = ffi.Int32 Function(
  ffi.Int32 __fd,
  ffi.Uint32 __request, 
  ffi.Pointer<ffi.Void> argp
);

typedef _c_ioctl_pointer_64 = ffi.Int32 Function(
  ffi.Int32 __fd,
  ffi.Uint64 __request,
  ffi.Pointer<ffi.Void> argp
);

typedef _dart_ioctl_pointer = int Function(
    int __fd, int __request, ffi.Pointer<ffi.Void> argp);

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

class LibC32 extends LibCInternal32 implements LibCBase {
  LibC32(this._dylib) : super(_dylib);

  final ffi.DynamicLibrary _dylib;

  @override
  int ioctlPointer(int __fd, int __request, ffi.Pointer argp) {
    _ioctlPointer ??=
        _dylib.lookupFunction<_c_ioctl_pointer_32, _dart_ioctl_pointer>('ioctl');
    return _ioctlPointer(__fd, __request, argp.cast<ffi.Void>());
  }

  _dart_ioctl_pointer _ioctlPointer;
}

class LibC64 extends LibCInternal64 implements LibCBase {
  LibC64(this._dylib) : super(_dylib);

  final ffi.DynamicLibrary _dylib;

  @override
  int ioctlPointer(int __fd, int __request, ffi.Pointer argp) {
    _ioctlPointer ??=
        _dylib.lookupFunction<_c_ioctl_pointer_64, _dart_ioctl_pointer>('ioctl');
    return _ioctlPointer(__fd, __request, argp.cast<ffi.Void>());
  }

  _dart_ioctl_pointer _ioctlPointer;
}

class LibC implements LibCBase {
  LibC._internal(this._native);
  
  factory LibC(ffi.DynamicLibrary dylib) {
    LibCBase _native;

    if (ffi.sizeOf<ffi.Pointer>() == 8) {
      _native = LibC64(dylib);
    } else {
      _native = LibC32(dylib);
    }

    return LibC._internal(_native);
  }

  final LibCBase _native;

  @override
  int close(int __fd) => _native.close(__fd);
  
  @override
  int epoll_create(int __size) => _native.epoll_create(__size);
  
  @override
  int epoll_create1(int __flags) => _native.epoll_create1(__flags);
  
  @override
  int epoll_ctl(int __epfd, int __op, int __fd, ffi.Pointer<epoll_event> __event)
    => _native.epoll_ctl(__epfd, __op, __fd, __event);

  @override
  int epoll_wait(int __epfd, ffi.Pointer<epoll_event> __events, int __maxevents, int __timeout)
    => _native.epoll_wait(__epfd, __events, __maxevents, __timeout);
  
  @override
  int ioctl(int __fd, int __request)
    => _native.ioctl(__fd, __request);

  @override
  int ioctlPointer(int __fd, int __request, ffi.Pointer<ffi.NativeType> argp)
    => _native.ioctlPointer(__fd, __request, argp);
  
  @override
  int open(ffi.Pointer<ffi.Int8> __file, int __oflag)
    => _native.open(__file, __oflag);

  @override
  int read(int __fd, ffi.Pointer<ffi.Void> __buf, int __nbytes)
    => _native.read(__fd, __buf, __nbytes);
}

T newStruct<T extends ffi.Struct>() {
  return ffi.allocate<T>().ref;
}

List<T> listFromArrayHelper<T>(int length, T getElement(int index)) {
  return List.generate(length, getElement, growable: false);
}

String stringFromInlineArray(int maxLength, int getElement(int index),
    {Encoding codec = const Utf8Codec(allowMalformed: true)}) {
  final list = listFromArrayHelper(maxLength, getElement);
  final length = list.indexOf(0);

  return codec.decode(list.sublist(0, length));
}

void writeStringToArrayHelper(
    String str, int length, void setElement(int index, int value),
    {Encoding codec = const Utf8Codec(allowMalformed: true)}) {
  codec.encode(str).take(length).toList().asMap().forEach(setElement);
}