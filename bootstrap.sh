#!/usr/bin/env bash
# bootstrap.sh — one-shot setup for a new machine
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/main/bootstrap.sh | bash
#   # — or, after cloning —
#   ./bootstrap.sh
set -euo pipefail

DOTFILES_REPO="https://github.com/jinwoo-choiter/dotfiles.git"
DOTFILES_DIR="${HOME}/.dotfiles"

# ─── Colours (inline — utils.sh may not be available yet) ────────────────────
_G='\033[0;32m'; _Y='\033[1;33m'; _R='\033[0;31m'; _N='\033[0m'
log_ok()    { echo -e "${_G}[OK]${_N}    $*"; }
log_info()  { echo -e "${_Y}[INFO]${_N}  $*"; }
log_error() { echo -e "${_R}[ERROR]${_N} $*" >&2; }

# ─── OS Detection ─────────────────────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "mac"   ;;
        *)       echo "unknown" ;;
    esac
}

OS="$(detect_os)"

# ─── Package install helpers ──────────────────────────────────────────────────
install_packages_linux() {
    log_info "Updating apt package index…"
    sudo apt-get update -qq

    local pkgs=(git curl wget unzip vim)
    log_info "Installing essential packages: ${pkgs[*]}"
    sudo apt-get install -y -qq "${pkgs[@]}"
}

install_packages_mac() {
    if ! command -v brew &>/dev/null; then
        log_info "Installing Homebrew…"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    local pkgs=(git curl wget vim)
    log_info "Installing essential packages: ${pkgs[*]}"
    brew install "${pkgs[@]}"
}

# ─── Clone or update repo ─────────────────────────────────────────────────────
ensure_repo() {
    if [[ -d "${DOTFILES_DIR}/.git" ]]; then
        log_info "dotfiles repo already exists at ${DOTFILES_DIR}, pulling latest…"
        git -C "$DOTFILES_DIR" pull --ff-only
    else
        log_info "Cloning dotfiles into ${DOTFILES_DIR}…"
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    echo "=== dotfiles bootstrap ==="
    echo "OS: ${OS}"
    echo ""

    # 1. Install essential packages
    case "$OS" in
        linux) install_packages_linux ;;
        mac)   install_packages_mac   ;;
        *)     log_error "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac
    log_ok "Essential packages installed"

    # 2. Clone / update dotfiles repo
    # If we're already running from inside the repo, skip cloning
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
        DOTFILES_DIR="$SCRIPT_DIR"
        log_info "Running from existing repo at ${DOTFILES_DIR}"
    else
        ensure_repo
    fi

    # 3. Run module installer
    log_info "Installing dotfiles modules…"
    bash "${DOTFILES_DIR}/install.sh"
    log_ok "Modules installed"

    # 4. Install apt / brew packages
    if [[ -f "${DOTFILES_DIR}/scripts/packages.sh" ]]; then
        log_info "Installing system packages…"
        bash "${DOTFILES_DIR}/scripts/packages.sh"
        log_ok "System packages installed"
    fi

    # 5. Install VSCode extensions (only if code CLI is available)
    if command -v code &>/dev/null; then
        if [[ -f "${DOTFILES_DIR}/scripts/vscode-ext.sh" ]]; then
            log_info "Installing VSCode extensions…"
            bash "${DOTFILES_DIR}/scripts/vscode-ext.sh"
            log_ok "VSCode extensions installed"
        fi
    else
        log_info "VSCode (code) not found — skipping extension install"
    fi

    echo ""
    echo "=== Bootstrap complete! ==="
    echo "Restart your shell or run: source ~/.bashrc"
}

main "$@"
