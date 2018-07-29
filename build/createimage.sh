#!/usr/bin/env bash

DIRSIZE=$(du -s ../ | cut -d '.' -f 1)
DIRSIZE=$((DIRSIZE + 10000))
echo "DIRSIZE: $DIRSIZE"


IMAGE=/tmp/image.bin
dd if=/dev/zero of=$IMAGE bs=1k count=$DIRSIZE
sudo mke2fs -t ext3 -F $IMAGE
mkdir mnt
sudo mount -o loop $IMAGE mnt
sudo rsync -r -a --exclude '.git' ../* mnt
sudo umount mnt

## Delete everything:
sudo rm -r ../*
mv $IMAGE ../image.bin