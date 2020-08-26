import 'dart:ffi' as ffi;

// ignore: camel_case_types
class epoll_event extends ffi.Struct {
  @ffi.Uint32()
  int events;
  @ffi.Uint64()
  int userdata;
}
