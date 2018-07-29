#!/usr/bin/env bash

DIRSIZE=$(du -s ../ | cut -d '.' -f 1)
DIRSIZE=$((DIRSIZE + 10000))
echo "DIRSIZE: $DIRSIZE"


IMAGE=/tmp/image.bin
dd if=/dev/zero of=$IMAGE bs=1k count=$DIRSIZE
sudo mke2fs -t ext3 $IMAGE
sudo mount -o loop $IMAGE /mnt
sudo rsync -r --verbose --exclude '.git' ../* /mnt
sudo umount /mnt

