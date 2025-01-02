#!/bin/sh

rootfs_dir=./rootfs
command_to_run=${1:-/bin/sh}

if [ ! -d "$rootfs_dir" ]; then
  echo "Rootfs directory not found: $rootfs_dir"
  exit 1
fi

exec "$rootfs_dir/usr/local/bin/proot" \
  --rootfs="$rootfs_dir" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit \
  /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  sh -c "$command_to_run"
