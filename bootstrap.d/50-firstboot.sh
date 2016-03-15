#
# First boot actions
# XXX: should be done by systemd-firstboot since stretch
#

# Load utility functions
. ./functions.sh

# Generate /etc/machine-id on boot
install_readonly files/firstboot/systemd-machine-id-setup.service $R/etc/systemd/system/systemd-machine-id-setup.service
chroot_exec systemctl enable systemd-machine-id-setup.service

# Prepare rc.firstboot script
cat files/firstboot/10-begin.sh > $R/etc/rc.firstboot

# Ensure openssh server host keys are regenerated on first boot
if [ "$ENABLE_SSHD" = true ] ; then
  cat files/firstboot/21-generate-ssh-keys.sh >> $R/etc/rc.firstboot
  rm -f $R/etc/ssh/ssh_host_*
fi

# Prepare filesystem auto expand
if [ "$EXPANDROOT" = true ] ; then
  cat files/firstboot/22-expandroot.sh >> $R/etc/rc.firstboot
fi

# Finalize rc.firstboot script
cat files/firstboot/99-finish.sh >> $R/etc/rc.firstboot
chmod +x $R/etc/rc.firstboot

# Add rc.firstboot script to rc.local
sed -i '/exit 0/d' $R/etc/rc.local
echo /etc/rc.firstboot >> $R/etc/rc.local
echo exit 0 >> $R/etc/rc.local
