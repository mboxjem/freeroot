#!/bin/sh

# Root filesystem directory
rootfs_dir=$(pwd)/rootfs
arch=$(uname -m)
export PATH="$PATH:$HOME/.local/usr/bin"

# Configuration
MAX_RETRIES=50
TIMEOUT=1
UBUNTU_VERSION=22.04
UBUNTU_BASE_URL="http://cdimage.ubuntu.com/ubuntu-base/releases/$UBUNTU_VERSION/release"
PROOT_URL="https://raw.githubusercontent.com/foxytouxxx/freeroot/main"

# Function to install Ubuntu
install_ubuntu() {
  echo "Downloading Ubuntu rootfs..."
  wget --tries="$MAX_RETRIES" --timeout="$TIMEOUT" --no-hsts -O /tmp/rootfs.tar.gz \
    "$UBUNTU_BASE_URL/ubuntu-base-$UBUNTU_VERSION-base-${arch_alt}.tar.gz"
  
  echo "Creating rootfs directory at $rootfs_dir..."
  mkdir -p "$rootfs_dir"

  echo "Extracting rootfs to $rootfs_dir..."
  tar -xf /tmp/rootfs.tar.gz -C "$rootfs_dir"
}
# Function to install proot
install_proot() {
  echo "Installing proot..."
  mkdir -p "$rootfs_dir/usr/local/bin"
  wget --tries="$MAX_RETRIES" --timeout="$TIMEOUT" --no-hsts -O "$rootfs_dir/usr/local/bin/proot" \
    "$PROOT_URL/proot-${arch}"

  retry_count=0
  while [ ! -s "$rootfs_dir/usr/local/bin/proot" ] && [ "$retry_count" -lt "$MAX_RETRIES" ]; do
    echo "Retrying proot download... Attempt $((retry_count + 1))"
    rm -f "$rootfs_dir/usr/local/bin/proot"
    wget --tries=1 --timeout="$TIMEOUT" --no-hsts -O "$rootfs_dir/usr/local/bin/proot" \
      "$PROOT_URL/proot-${arch}"
    sleep 1
    retry_count=$((retry_count + 1))
  done

  if [ ! -s "$rootfs_dir/usr/local/bin/proot" ]; then
    echo "Failed to download proot after $MAX_RETRIES attempts."
    exit 1
  fi

  chmod 755 "$rootfs_dir/usr/local/bin/proot"
}

# Function to configure resolv.conf
configure_resolv() {
  echo "Configuring DNS resolv.conf..."
  cat > "$rootfs_dir/etc/resolv.conf" <<EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
}

# Validate architecture
case "$arch" in
  x86_64) arch_alt=amd64 ;;
  aarch64) arch_alt=arm64 ;;
  *) echo "Unsupported CPU architecture: $arch"; exit 1 ;;
esac

# Perform installation if not already completed
if [ ! -e "$rootfs_dir/.installed" ]; then
  install_ubuntu
  install_proot
  configure_resolv
  touch "$rootfs_dir/.installed"
  echo "Installation complete."
fi

# Run proot
echo "Starting proot..."

command_to_run=${1:-/bin/sh}
exec "$rootfs_dir/usr/local/bin/proot" \
  --rootfs="$rootfs_dir" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit \
  /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  sh -c "$command_to_run"
