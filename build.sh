#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH="${FC_KERNELS_ARCH:-x86_64}"
KERNEL_VERSION="${FC_KERNELS_KERNEL_VERSION:-$(awk 'NF && $1 !~ /^#/' "$ROOT_DIR/kernel_versions.txt" | head -n 1)}"
OUTPUT_DIR="${FC_KERNELS_OUTPUT_DIR:-$ROOT_DIR/.out}"
LINUX_REPO_DIR="${FC_KERNELS_LINUX_REPO_DIR:-$ROOT_DIR/.work/linux}"
JOBS="${FC_KERNELS_JOBS:-$(nproc)}"
SOURCE_REPO_URL="${FC_KERNELS_SOURCE_REPO_URL:-https://github.com/amazonlinux/linux.git}"

usage() {
  cat <<'EOF'
Usage: build.sh [--arch <arch>] [--kernel-version <version>] [--output-dir <dir>] [--linux-repo-dir <dir>] [--jobs <n>]
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
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --linux-repo-dir)
      LINUX_REPO_DIR="$2"
      shift 2
      ;;
    --jobs)
      JOBS="$2"
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
if [[ -z "$KERNEL_VERSION" ]]; then
  echo "kernel version is required" >&2
  exit 1
fi
if [[ "$ARCH" != "x86_64" ]]; then
  echo "unsupported arch: $ARCH" >&2
  exit 1
fi
if ! [[ "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
  echo "jobs must be a positive integer: $JOBS" >&2
  exit 1
fi

require_tool() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "required tool missing: $1" >&2
    exit 1
  }
}

resolve_source_tag() {
  local version="$1"
  local tags
  local tag

  tags="$(
    git ls-remote --tags "$SOURCE_REPO_URL" \
      | awk '{print $2}' \
      | sed 's#refs/tags/##; s/\^{}$//' \
      | sort -uV
  )"
  tag="$(printf '%s\n' "$tags" | grep -E "^microvm-kernel-${version}-.*\\.amzn2023$" | tail -n 1 || true)"
  if [[ -z "$tag" ]]; then
    tag="$(printf '%s\n' "$tags" | grep -E "^kernel-${version}-.*\\.amzn2023$" | tail -n 1 || true)"
  fi
  if [[ -z "$tag" ]]; then
    echo "no Amazon Linux source tag found for kernel version $version" >&2
    exit 1
  fi

  printf '%s\n' "$tag"
}

prepare_linux_repo() {
  local source_tag="$1"

  mkdir -p "$(dirname "$LINUX_REPO_DIR")"
  if [[ ! -d "$LINUX_REPO_DIR/.git" ]]; then
    git clone --depth=1 --branch "$source_tag" "$SOURCE_REPO_URL" "$LINUX_REPO_DIR" >/dev/null
  else
    git -C "$LINUX_REPO_DIR" fetch --depth=1 origin "refs/tags/${source_tag}:refs/tags/${source_tag}" >/dev/null
    git -C "$LINUX_REPO_DIR" checkout --force "$source_tag" >/dev/null
  fi

  git -C "$LINUX_REPO_DIR" checkout --force "$source_tag" >/dev/null
  git -C "$LINUX_REPO_DIR" clean -fdx >/dev/null
}

require_tool git
require_tool make
require_tool sha256sum

SOURCE_TAG="$(resolve_source_tag "$KERNEL_VERSION")"
prepare_linux_repo "$SOURCE_TAG"

make -C "$LINUX_REPO_DIR" mrproper >/dev/null
cp "$CONFIG_PATH" "$LINUX_REPO_DIR/.config"
make -C "$LINUX_REPO_DIR" olddefconfig >/dev/null
make -C "$LINUX_REPO_DIR" -j "$JOBS" vmlinux >/dev/null

ARTIFACT_DIR="$OUTPUT_DIR/vmlinux-${KERNEL_VERSION}/${ARCH}"
mkdir -p "$ARTIFACT_DIR"
cp "$LINUX_REPO_DIR/vmlinux" "$ARTIFACT_DIR/vmlinux"
cp "$LINUX_REPO_DIR/.config" "$ARTIFACT_DIR/kernel.config"
sha256sum "$ARTIFACT_DIR/vmlinux" >"$ARTIFACT_DIR/vmlinux.sha256"
cat >"$ARTIFACT_DIR/metadata.json" <<EOF
{"arch":"$ARCH","kernel_version":"$KERNEL_VERSION","source_repo":"$SOURCE_REPO_URL","source_tag":"$SOURCE_TAG"}
EOF

printf '%s\n' "$ARTIFACT_DIR"
