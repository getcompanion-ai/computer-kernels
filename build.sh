#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH="${FC_KERNELS_ARCH:-x86_64}"
KERNEL_VERSION="${FC_KERNELS_KERNEL_VERSION:-$(head -n 1 "$ROOT_DIR/kernel_versions.txt")}"

usage() {
  cat <<'EOF'
Usage: build.sh [--arch <arch>] [--kernel-version <version>]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch)
      ARCH="$2"
      shift 2
      ;;
    --kernel-version)
      KERNEL_VERSION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

CONFIG_PATH="$ROOT_DIR/configs/$ARCH/${KERNEL_VERSION}.config"
if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "missing kernel config: $CONFIG_PATH" >&2
  exit 1
fi

echo "fc-kernels scaffold ready"
echo "arch=$ARCH"
echo "kernel_version=$KERNEL_VERSION"
echo "config=$CONFIG_PATH"
