#!/bin/sh
# cync installer — detects OS/arch, downloads the right binary, installs it.
#
#   curl -fsSL https://cync.run/install.sh | sh
#
# Options (env vars):
#   CYNC_INSTALL_DIR  — where to put the binary (default: ~/.local/bin)
#   CYNC_VERSION      — pin a version (default: latest)
set -eu

REPO="cync-cli/homebrew-tap"
INSTALL_DIR="${CYNC_INSTALL_DIR:-$HOME/.local/bin}"

info()  { printf '\033[1;34m%s\033[0m\n' "$*"; }
error() { printf '\033[1;31merror: %s\033[0m\n' "$*" >&2; exit 1; }

detect_platform() {
  OS=$(uname -s)
  ARCH=$(uname -m)

  case "$OS" in
    Darwin) OS=macos ;;
    Linux)  OS=linux ;;
    *)      error "unsupported OS: $OS (cync ships macOS and Linux binaries)" ;;
  esac

  case "$ARCH" in
    x86_64|amd64)   ARCH=x86_64 ;;
    arm64|aarch64)   ARCH=arm64 ;;
    *)               error "unsupported architecture: $ARCH" ;;
  esac

  # We only ship macOS arm64 and Linux x86_64
  if [ "$OS" = "macos" ] && [ "$ARCH" = "x86_64" ]; then
    error "Intel Mac binaries aren't shipped — install via: pipx install cync-cli"
  fi
  if [ "$OS" = "linux" ] && [ "$ARCH" = "arm64" ]; then
    error "Linux ARM binaries aren't shipped yet — install via: pipx install cync-cli"
  fi

  TARGET="${OS}-${ARCH}"
}

resolve_version() {
  if [ -n "${CYNC_VERSION:-}" ]; then
    VERSION="$CYNC_VERSION"
    return
  fi
  # GitHub redirects /releases/latest to the actual tag — grab it from the Location header.
  VERSION=$(curl -fsSI "https://github.com/$REPO/releases/latest" 2>/dev/null \
    | grep -i '^location:' | sed 's|.*/v||; s/[[:space:]]//g')
  if [ -z "$VERSION" ]; then
    error "could not detect latest version — set CYNC_VERSION=0.6.0 and retry"
  fi
}

download_and_install() {
  URL="https://github.com/$REPO/releases/download/v${VERSION}/cync-${TARGET}.tar.gz"
  info "downloading cync $VERSION ($TARGET)..."

  TMPDIR_DL=$(mktemp -d)
  trap 'rm -rf "$TMPDIR_DL"' EXIT

  HTTP_CODE=$(curl -fsSL -o "$TMPDIR_DL/cync.tar.gz" -w '%{http_code}' "$URL" 2>/dev/null) || true
  if [ ! -f "$TMPDIR_DL/cync.tar.gz" ] || [ "$HTTP_CODE" = "404" ]; then
    error "binary not found at $URL — check https://github.com/$REPO/releases"
  fi

  tar -xzf "$TMPDIR_DL/cync.tar.gz" -C "$TMPDIR_DL"
  if [ ! -f "$TMPDIR_DL/cync" ]; then
    error "tarball did not contain a 'cync' binary"
  fi

  mkdir -p "$INSTALL_DIR"
  mv "$TMPDIR_DL/cync" "$INSTALL_DIR/cync"
  chmod +x "$INSTALL_DIR/cync"
}

add_to_path() {
  case ":${PATH}:" in
    *":${INSTALL_DIR}:"*) return ;;  # already on PATH
  esac

  SHELL_NAME=$(basename "${SHELL:-/bin/sh}")
  case "$SHELL_NAME" in
    zsh)  RC="$HOME/.zshrc" ;;
    bash)
      if [ -f "$HOME/.bash_profile" ]; then RC="$HOME/.bash_profile"
      else RC="$HOME/.bashrc"; fi
      ;;
    fish)
      mkdir -p "$HOME/.config/fish"
      RC="$HOME/.config/fish/config.fish"
      ;;
    *)    RC="" ;;
  esac

  if [ -n "$RC" ]; then
    if [ "$SHELL_NAME" = "fish" ]; then
      LINE="fish_add_path $INSTALL_DIR"
    else
      LINE="export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
    if ! grep -qF "$INSTALL_DIR" "$RC" 2>/dev/null; then
      printf '\n# cync\n%s\n' "$LINE" >> "$RC"
      info "added $INSTALL_DIR to PATH in $RC"
      info "run: source $RC  (or open a new terminal)"
    fi
  else
    info "add $INSTALL_DIR to your PATH manually"
  fi
}

main() {
  detect_platform
  resolve_version
  download_and_install

  INSTALLED_VERSION=$("$INSTALL_DIR/cync" --version 2>/dev/null || echo "unknown")
  info "installed: $INSTALLED_VERSION"
  info "location:  $INSTALL_DIR/cync"

  add_to_path

  printf '\n'
  info "run: cync login"
}

main
