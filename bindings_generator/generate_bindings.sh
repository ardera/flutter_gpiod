#!/bin/bash

pub run ffigen --config ffigen_libc_constants_config.yaml
pub run ffigen --config ffigen_libc32_config.yaml
pub run ffigen --config ffigen_libc64_config.yaml
pub run ffigen --config ffigen_gpio_config.yaml

sed -i '/import/d' ../lib/src/bindings/libc_constants.g.dart
sed -i '/class epoll_event/d' ../lib/src/bindings/libc32_bindings.g.dart
sed -i '/class epoll_event/d' ../lib/src/bindings/libc64_bindings.g.dart
sed -i '/import/d' ../lib/src/bindings/gpio_bindings.g.dart

dartfmt -w ../lib/src/bindings