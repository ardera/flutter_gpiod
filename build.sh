#!/bin/bash -i

pushd ./bindings_generator
./generate_bindings.sh
popd

cmd.exe /C flutter build bundle --target=example/lib/main.dart

rsync -a ./build/flutter_assets/ hpi4:/home/pi/devel/flutter_gpiod_assets