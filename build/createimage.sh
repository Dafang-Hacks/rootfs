#!/usr/bin/env bash
IMAGE=image.bin
dd if=/dev/zero of=$IMAGE bs=1k count=16384
sudo mke2fs -t ext3 $IMAGE
sudo mount -o loop $IMAGE /mnt
cp -r ./ /mnt
sudo umount /mnt

