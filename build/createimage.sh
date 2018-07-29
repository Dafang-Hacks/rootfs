#!/usr/bin/env bash
IMAGE=image.bin
dd if=/dev/zero of=$IMAGE bs=1k count=16384
mke2fs -t ext3 -f $IMAGE
mount -o loop $IMAGE /mnt
cp -r /source /mnt
umount /mnt

