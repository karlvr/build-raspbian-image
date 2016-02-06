#!/bin/sh

vmdebootstrap \
    --arch armhf \
    --distribution jessie \
    --mirror http://[::1]:3142/archive.raspbian.org/raspbian \
    --image `date +raspbian-%Y%m%d.img` \
    --size 2000M \
    --bootsize 64M \
    --boottype vfat \
    --root-password raspberry \
    --enable-dhcp \
    --verbose \
    --no-kernel \
    --no-extlinux \
    --hostname raspberry \
    --foreign /usr/bin/qemu-arm-static \
    --debootstrapopts="variant=minbase keyring=`pwd`/raspbian.org.gpg" \
    --customize `pwd`/customize.sh
