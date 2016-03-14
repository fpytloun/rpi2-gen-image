#
# Setup APT repositories
#

# Load utility functions
. ./functions.sh

# Install and setup APT proxy configuration
if [ -z "$APT_PROXY" ] ; then
  install_readonly files/apt/10proxy $R/etc/apt/apt.conf.d/10proxy
  sed -i "s/\"\"/\"${APT_PROXY}\"/" $R/etc/apt/apt.conf.d/10proxy
fi

chroot_exec apt-get install -qq -y wget
echo "deb http://apt.tcpcloud.eu/debian/ ${RELEASE} rpi" > $R/etc/apt/sources.list.d/tcpcloud.list
chroot_exec wget http://apt.tcpcloud.eu/public.gpg
chroot_exec apt-key add public.gpg
chroot_exec rm -f public.gpg
chroot_exec apt-get -qq -y update

# Install APT sources.list
install_readonly files/apt/sources.list $R/etc/apt/sources.list
sed -i "s/\/ftp.debian.org\//\/${APT_SERVER}\//" $R/etc/apt/sources.list
sed -i "s/ jessie/ ${RELEASE}/" $R/etc/apt/sources.list

# Upgrade package index and update all installed packages and changed dependencies
chroot_exec apt-get -qq -y update
chroot_exec apt-get -qq -y -u dist-upgrade
chroot_exec apt-get -qq -y check
