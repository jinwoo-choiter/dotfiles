#!/usr/bin/env bash
# scripts/vscode-ext.sh — bulk-install VSCode extensions from extensions.txt
#
# Usage: ./scripts/vscode-ext.sh [path/to/extensions.txt]
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${DOTFILES_DIR}/lib/utils.sh"

EXT_FILE="${1:-${DOTFILES_DIR}/modules/vscode/extensions.txt}"

# ─── Checks ───────────────────────────────────────────────────────────────────
if ! command -v code &>/dev/null; then
    log_error "'code' CLI not found. Install VSCode and make sure 'code' is in PATH."
    log_error "  Linux: launch VSCode → Command Palette → 'Install code command in PATH'"
    exit 1
fi

if [[ ! -f "$EXT_FILE" ]]; then
    log_error "Extensions file not found: ${EXT_FILE}"
    exit 1
fi

# ─── Install ──────────────────────────────────────────────────────────────────
main() {
    echo "=== Installing VSCode extensions from ${EXT_FILE} ==="

    local installed=0 skipped=0 failed=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Strip comments and blank lines
        line="${line%%#*}"
        line="$(echo "$line" | tr -d '[:space:]')"
        [[ -z "$line" ]] && continue

        if code --install-extension "$line" --force &>/dev/null; then
            log_ok "$line"
            (( installed++ )) || true
        else
            log_error "$line"
            (( failed++ )) || true
        fi
    done < "$EXT_FILE"

    echo ""
    echo "=== VSCode extensions summary ==="
    log_ok   "Installed : ${installed}"
    if [[ $failed -gt 0 ]]; then
        log_error "Failed    : ${failed}"
        exit 1
    fi
}

main "$@"
