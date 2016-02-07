#!/bin/sh -e

check_installed() {
    type $1 2>&1 >/dev/null || { echo >&2 "$1 not installed"; exit 1; }
}

check_installed vmdebootstrap
check_installed apt-cacher-ng
check_installed qemu-arm-static

vmdebootstrap \
    --arch armhf \
    --distribution jessie \
    --mirror http://[::1]:3142/archive.raspbian.org/raspbian \
    --image `date +raspbian-%Y%m%d.img` \
    --size 2000M \
    --bootsize 64M \
    --boottype vfat \
    --lock-root-password \
    --sudo \
    --user pi/raspberry \
    --enable-dhcp \
    --verbose \
    --no-kernel \
    --no-extlinux \
    --hostname raspberry \
    --foreign /usr/bin/qemu-arm-static \
    --debootstrapopts="variant=minbase keyring=`pwd`/raspbian.org.gpg" \
    --customize `pwd`/customize.sh
