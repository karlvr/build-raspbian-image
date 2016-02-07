#!/bin/sh
set -e

ROOTDIR="$1"

# Do not start services during installation.
echo exit 101 > $ROOTDIR/usr/sbin/policy-rc.d
chmod +x $ROOTDIR/usr/sbin/policy-rc.d

export LANG=POSIX

# First boot script.
cp etc/init.d/firstboot $ROOTDIR/etc/init.d/firstboot
chmod a+x $ROOTDIR/etc/init.d/firstboot
chroot $ROOTDIR update-rc.d firstboot defaults

# Configure apt.
export DEBIAN_FRONTEND=noninteractive
cat raspbian.org.gpg | chroot $ROOTDIR apt-key add -
cat raspberrypi.gpg | chroot $ROOTDIR apt-key add -
mkdir -p $ROOTDIR/etc/apt/sources.list.d/
mkdir -p $ROOTDIR/etc/apt/apt.conf.d/
echo "Acquire::http { Proxy \"http://[::1]:3142\"; };" > $ROOTDIR/etc/apt/apt.conf.d/50apt-cacher-ng
cp etc/apt/sources.list $ROOTDIR/etc/apt/sources.list
cp etc/apt/apt.conf.d/50raspi $ROOTDIR/etc/apt/apt.conf.d/50raspi
chroot $ROOTDIR apt-get update

# Configure.
cp boot/cmdline.txt $ROOTDIR/boot/cmdline.txt
cp boot/config.txt $ROOTDIR/boot/config.txt
cp etc/fstab $ROOTDIR/etc/fstab
cp etc/modules $ROOTDIR/etc/modules
cp etc/network/interfaces $ROOTDIR/etc/network/interfaces

# Install kernel.
mkdir -p $ROOTDIR/lib/modules
chroot $ROOTDIR apt-get install -y ca-certificates kmod rpi-update
SKIP_WARNING=1 SKIP_BACKUP=1 ROOT_PATH=$ROOTDIR BOOT_PATH=$ROOTDIR/boot $ROOTDIR/usr/bin/rpi-update

# Install extra packages.
chroot $ROOTDIR apt-get install -y apt-utils vim-tiny nano whiptail netbase less iputils-ping net-tools isc-dhcp-client man-db
chroot $ROOTDIR apt-get install -y anacron fake-hwclock

# Regenerate SSH host keys on first boot.
chroot $ROOTDIR apt-get install -y openssh-server
rm -f $ROOTDIR/etc/ssh/ssh_host_*

# Raspberry Pi packages.
# /spindle_install stops raspi-copies-and-fills from creating /etc/ld.so.preload and breaking qemu.
touch $ROOTDIR/spindle_install
chroot $ROOTDIR apt-get install -y raspi-config raspi-copies-and-fills rng-tools locales

# Install other recommended packages.
#apt-get install ntp apt-cron fail2ban needrestart
chroot $ROOTDIR apt-get install -y ntp avahi-daemon

# Create a swapfile.
#dd if=/dev/zero of=$ROOTDIR/var/swapfile bs=1M count=512
#chroot $ROOTDIR mkswap /var/swapfile
#echo /var/swapfile none swap sw 0 0 >> $ROOTDIR/etc/fstab

# Custom installs.
if [ -d custom ]; then
	cp -r custom $ROOTDIR/
	for i in $ROOTDIR/custom/*.sh ; do
		chmod +x $i
		chroot $ROOTDIR /custom/$(basename $i)
	done
	rm -rf $ROODIR/custom
fi

# Done.
rm $ROOTDIR/usr/sbin/policy-rc.d
rm $ROOTDIR/etc/apt/apt.conf.d/50apt-cacher-ng
