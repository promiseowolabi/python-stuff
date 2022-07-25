#!/usr/bin/env bash

yum install nfs-utils -y -q

mkdir -p /mnt/ontap
echo "Mounting ${dnsname}:${volpath}"
mount -t nfs -o nconnect=16 ${dnsname}:${volpath} /mnt/ontap
# example:
# mount -t nfs -o nconnect=16 svm-09cd6e661d2e6eb37.fs-05e4ec2b6ffc8378c.fsx.us-east-1.amazonaws.com:/vol /mnt/ontap