export QEMU_BINARY=/usr/bin/qemu-aarch64-static
export KERNEL_ARCH=arm64
export RELEASE_ARCH=arm64
export BUILD_KERNEL=true
export KERNEL_HEADERS=true

./rpi2-gen-image.sh
