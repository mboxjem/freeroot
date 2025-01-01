#!/bin/sh

rootfs_dir=$(pwd)
arch=$(uname -m)
export PATH="$PATH:~/.local/usr/bin"
MAX_RETRIES=50
TIMEOUT=1
UBUNTU_VERSION=22.04

install_ubuntu() {
  wget --tries="$MAX_RETRIES" --timeout="$TIMEOUT" --no-hsts -O /tmp/rootfs.tar.gz \
    "http://cdimage.ubuntu.com/ubuntu-base/releases/$UBUNTU_VERSION/release/ubuntu-base-$UBUNTU_VERSION-base-${arch_alt}.tar.gz"
  tar -xf /tmp/rootfs.tar.gz -C "$rootfs_dir"
}

install_proot() {
  mkdir -p "$rootfs_dir/usr/local/bin"
  wget --tries="$MAX_RETRIES" --timeout="$TIMEOUT" --no-hsts -O "$rootfs_dir/usr/local/bin/proot" "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${arch}"

  while [ ! -s "$rootfs_dir/usr/local/bin/proot" ]; do
    rm -rf "$rootfs_dir/usr/local/bin/proot"
    wget --tries="$MAX_RETRIES" --timeout="$TIMEOUT" --no-hsts -O "$rootfs_dir/usr/local/bin/proot" "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${arch}"
    sleep 1
  done

  chmod 755 "$rootfs_dir/usr/local/bin/proot"
}

configure_resolv() {
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > "$rootfs_dir/etc/resolv.conf"
}

if [ "$arch" = "x86_64" ]; then
  arch_alt=amd64
elif [ "$arch" = "aarch64" ]; then
  arch_alt=arm64
else
  printf "Unsupported CPU architecture: %s\n" "$arch"
  exit 1
fi

if [ ! -e "$rootfs_dir/.installed" ]; then
  install_ubuntu
  install_proot
  configure_resolv
  touch "$rootfs_dir/.installed"
  printf "Mission Completed\n"
fi

"$rootfs_dir/usr/local/bin/proot" \
  --rootfs="$rootfs_dir" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
