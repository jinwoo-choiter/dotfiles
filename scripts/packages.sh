#!/usr/bin/env bash
# scripts/packages.sh — install system packages
#
# Usage: ./scripts/packages.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${DOTFILES_DIR}/lib/utils.sh"

# ─── Package lists ────────────────────────────────────────────────────────────

APT_PACKAGES=(
    # Shell & terminal
    bash-completion
    tmux
    terminator
    zsh

    # Editors
    vim
    neovim

    # Dev tools
    git
    curl
    wget
    unzip
    zip
    jq
    tree
    htop
    ripgrep
    fd-find
    bat
    fzf

    # Build tools
    build-essential
    cmake
    pkg-config

    # Language runtimes
    python3
    python3-pip
    python3-venv
    nodejs
    npm

    # Network
    openssh-client
    net-tools
    nmap
)

BREW_PACKAGES=(
    bash-completion
    tmux
    vim
    neovim
    git
    curl
    wget
    jq
    tree
    htop
    ripgrep
    fd
    bat
    fzf
    python3
    node
)

# ─── Install ──────────────────────────────────────────────────────────────────
install_linux() {
    log_ok "Updating apt package index…"
    sudo apt-get update -qq

    log_ok "Installing ${#APT_PACKAGES[@]} packages via apt…"
    sudo apt-get install -y "${APT_PACKAGES[@]}"

    # bat is installed as 'batcat' on Ubuntu — create alias
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        mkdir -p ~/.local/bin
        ln -sf "$(command -v batcat)" ~/.local/bin/bat
        log_ok "Created bat → batcat symlink in ~/.local/bin"
    fi

    # fd is installed as 'fdfind' on Ubuntu — create alias
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        mkdir -p ~/.local/bin
        ln -sf "$(command -v fdfind)" ~/.local/bin/fd
        log_ok "Created fd → fdfind symlink in ~/.local/bin"
    fi
}

install_mac() {
    if ! command -v brew &>/dev/null; then
        log_error "Homebrew not found. Run bootstrap.sh first."
        exit 1
    fi

    log_ok "Installing ${#BREW_PACKAGES[@]} packages via Homebrew…"
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
