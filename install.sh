#!/usr/bin/env bash
# install.sh — dotfiles module installer
#
# Usage:
#   ./install.sh              # install all modules
#   ./install.sh bash git     # install specific modules only
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${DOTFILES_DIR}/modules"

# shellcheck source=lib/utils.sh
source "${DOTFILES_DIR}/lib/utils.sh"

# ─── Helpers ──────────────────────────────────────────────────────────────────
usage() {
    echo "Usage: $0 [module1 module2 ...]"
    echo "  No arguments → install all modules"
    echo "  With arguments → install only listed modules"
}

install_module() {
    local module_name="$1"
    local module_dir="${MODULES_DIR}/${module_name}"
    local conf_file="${module_dir}/install.conf"

    if [[ ! -d "$module_dir" ]]; then
        log_error "Module directory not found: $module_dir"
        return 1
    fi

    if [[ ! -f "$conf_file" ]]; then
        log_error "install.conf not found in module: $module_name"
        return 1
    fi

    echo ""
    echo "── Module: ${module_name} ──"
    parse_and_apply "$conf_file" "$module_dir" "$module_name"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    local total_ok=0 total_skip=0 total_err=0
    local modules_to_install=()

    if [[ $# -eq 0 ]]; then
        # Install all modules (sorted)
        while IFS= read -r -d '' mod_dir; do
            modules_to_install+=("$(basename "$mod_dir")")
        done < <(find "$MODULES_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    else
        modules_to_install=("$@")
    fi

    if [[ ${#modules_to_install[@]} -eq 0 ]]; then
        log_error "No modules found in ${MODULES_DIR}"
        exit 1
    fi

    echo "=== dotfiles installer ==="
    echo "OS: $(detect_os)"
    echo "Modules: ${modules_to_install[*]}"

    for mod in "${modules_to_install[@]}"; do
        if install_module "$mod"; then
            (( total_ok   += _LAST_OK   )) || true
            (( total_skip += _LAST_SKIP )) || true
            (( total_err  += _LAST_ERR  )) || true
        else
            (( total_err++ )) || true
        fi
    done

    echo ""
    echo "=== Summary ==="
    log_ok    "Success : ${total_ok}"
    log_skip  "Skipped : ${total_skip}"
    if [[ $total_err -gt 0 ]]; then
        log_error "Errors  : ${total_err}"
        exit 1
    fi
}

main "$@"
