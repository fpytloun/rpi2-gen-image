#
# Kernel installation
#

. ./functions.sh

# Fetch and build latest raspberry kernel
if [ "$BUILD_KERNEL" = true ] ; then
  # Fetch current raspberrypi kernel sources
  git -C $R/tmp clone --depth=1 https://github.com/raspberrypi/linux

  # Load default raspberry kernel configuration
  make -C $R/tmp/linux ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig

  # Cross compile kernel and modules
  make -C $R/tmp/linux -j 8 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs

  # Install kernel modules
  make -C $R/tmp/linux ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=../.. modules_install

  # Copy and rename compiled kernel to boot directory
  mkdir $R/boot/firmware/
  $R/tmp/linux/scripts/mkknlimg $R/tmp/linux/arch/arm/boot/zImage $R/boot/firmware/kernel7.img

  # Copy dts and dtb device definitions
  mkdir $R/boot/firmware/overlays/
  cp $R/tmp/linux/arch/arm/boot/dts/*.dtb $R/boot/firmware/
  cp $R/tmp/linux/arch/arm/boot/dts/overlays/*.dtb* $R/boot/firmware/overlays/
  cp $R/tmp/linux/arch/arm/boot/dts/overlays/README $R/boot/firmware/overlays/

  # Install raspberry bootloader and flash-kernel
  chroot_exec apt-get -qq -y --no-install-recommends install raspberrypi-bootloader-nokernel
else
  # Kernel installation
  chroot_exec apt-get -qq -y --no-install-recommends install linux-image-${KERNEL} raspberrypi-bootloader-nokernel

  # Install flash-kernel last so it doesn't try (and fail) to detect the platform in the chroot
  chroot_exec apt-get -qq -y install flash-kernel

  VMLINUZ="$(ls -1 $R/boot/vmlinuz-* | sort | tail -n 1)"
  [ -z "$VMLINUZ" ] && exit 1
  cp $VMLINUZ $R/boot/firmware/kernel7.img
fi

# Set up firmware boot cmdline
CMDLINE="dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootfstype=ext4 rootflags=commit=100,data=writeback elevator=deadline rootwait net.ifnames=1 console=tty1"

# Set up serial console support (if requested)
if [ "$ENABLE_CONSOLE" = true ] ; then
  CMDLINE="${CMDLINE} console=ttyAMA0,115200 kgdboc=ttyAMA0,115200"
fi

# Set up IPv6 networking support
if [ "$ENABLE_IPV6" = false ] ; then
  CMDLINE="${CMDLINE} ipv6.disable=1"
fi

echo "${CMDLINE}" >$R/boot/firmware/cmdline.txt

# Set up firmware config
install -o root -g root -m 644 files/config.txt $R/boot/firmware/config.txt

# Load snd_bcm2835 kernel module at boot time
if [ "$ENABLE_SOUND" = true ] ; then
  echo "snd_bcm2835" >>$R/etc/modules
fi

# Set smallest possible GPU memory allocation size: 16MB (no X)
if [ "$ENABLE_MINGPU" = true ] ; then
  echo "gpu_mem=16" >>$R/boot/firmware/config.txt
fi

# Create symlinks
ln -sf firmware/config.txt $R/boot/config.txt
ln -sf firmware/cmdline.txt $R/boot/cmdline.txt

# Prepare modules-load.d directory
mkdir -p $R/lib/modules-load.d/

# Load random module on boot
if [ "$ENABLE_HWRANDOM" = true ] ; then
  cat <<EOM >$R/lib/modules-load.d/rpi2.conf
bcm2708_rng
EOM
fi

# Prepare modprobe.d directory
mkdir -p $R/etc/modprobe.d/

# Blacklist sound modules
install -o root -g root -m 644 files/modprobe.d/raspi-blacklist.conf $R/etc/modprobe.d/raspi-blacklist.conf

# Create default fstab
install -o root -g root -m 644 files/fstab $R/etc/fstab

# Avoid swapping and increase cache sizes
install -o root -g root -m 644 files/sysctl.d/81-rpi-vm.conf $R/etc/sysctl.d/81-rpi-vm.conf