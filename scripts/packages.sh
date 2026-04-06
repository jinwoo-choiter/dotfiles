#!/usr/bin/env bash
# scripts/packages.sh — install packages required by dotfiles modules
#
# Only installs what the modules in modules/ actually need.
# Development tools (cmake, python, nodejs, etc.) are intentionally
# excluded — install those separately as needed.
#
# Usage: ./scripts/packages.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${DOTFILES_DIR}/lib/utils.sh"

# ─── Package lists ────────────────────────────────────────────────────────────
# Keyed to modules/:
#   git        → git
#   ssh        → openssh-client
#   terminator → terminator

APT_PACKAGES=(
    git
    openssh-client
    terminator
)

BREW_PACKAGES=(
    git
    openssh
    # terminator is Linux-only; on macOS use iTerm2 or another terminal
)

# ─── Install ──────────────────────────────────────────────────────────────────
install_linux() {
    log_ok "Updating apt package index…"
    sudo apt-get update -qq

    log_ok "Installing packages required by dotfiles modules…"
    sudo apt-get install -y "${APT_PACKAGES[@]}"
}

install_mac() {
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew not found. Run bootstrap.sh first."
        exit 1
    fi

    log_ok "Installing packages required by dotfiles modules…"
    brew install "${BREW_PACKAGES[@]}"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    local os
    os="$(detect_os)"
    echo "=== Installing system packages (OS: ${os}) ==="

    case "$os" in
        linux) install_linux ;;
        mac)   install_mac   ;;
        *)
            log_error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac

    log_ok "Package installation complete"
}

main "$@"
