## 0.3.2

*updated and adapted to ffi 1.0.0 

## 0.3.1

* fix docs for `GpioChip.label`

## 0.3.0

* `GpioLine.onEvent` is now a broadcast (not single subscription) stream
* example was updated to include some gotchas with this single subscription stream
* fix a bug with closing event lines

## 0.2.0

* switch to using FFI
* libgpiod is no longer required, the interface accesses the GPIO character devices directly using ioctls
* a lot of stuff has been made synchronous
* add a sub-project for generating the FFI bindings ("bindings_generator")
* update the examples for the new API
* fix some documentation
* tested on ARM32, should work on other 32-bit and 64-bit linux platforms as well (untested though)

## 0.1.0+3

* Removed link in `pubspec.yaml` because it wasn't working.

## 0.1.0+2

* Format sources
* Better description in `pubspec.yaml`

## 0.1.0+1

* Fix `README.md`

## 0.1.0

* Initial release.
