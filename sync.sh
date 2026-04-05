#!/usr/bin/env bash
# sync.sh — bidirectional sync between local dotfiles and git repo
#
# Usage:
#   ./sync.sh          # pull then push any local changes
#   ./sync.sh --pull   # only pull (repo → local)
#   ./sync.sh --push   # only push (local → repo)
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
source "${DOTFILES_DIR}/lib/utils.sh"

# ─── Helpers ──────────────────────────────────────────────────────────────────
usage() {
    echo "Usage: $0 [--pull | --push]"
    echo "  (no flag)  pull changes then push local changes"
    echo "  --pull     pull from remote and re-apply append/copy modules"
    echo "  --push     stage, commit, and push local changes"
}

# Returns 0 if there are any append or copy modules (need re-install after pull)
has_non_symlink_modules() {
    grep -rlE '^(append|copy)\s' "${DOTFILES_DIR}/modules/" &>/dev/null
}

do_pull() {
    log_ok "Pulling from remote…"
    if ! git -C "$DOTFILES_DIR" pull --ff-only 2>&1; then
        log_error "Pull failed (possible conflict). Resolve manually and re-run."
        log_error "  cd ${DOTFILES_DIR} && git status"
        exit 1
    fi

    if has_non_symlink_modules; then
        echo ""
        echo "Some modules use 'append' or 'copy' mode."
        echo "Re-running install.sh to apply any remote changes…"
        bash "${DOTFILES_DIR}/install.sh"
        log_ok "Modules re-applied"
    else
        log_ok "All modules use symlinks — no re-install needed"
    fi
}

do_push() {
    cd "$DOTFILES_DIR"

    local status
    status="$(git status --porcelain)"

    if [[ -z "$status" ]]; then
        log_skip "Nothing to commit — working tree clean"
        return 0
    fi

    log_ok "Changes detected:"
    git status --short

    local hostname
    hostname="$(hostname -s 2>/dev/null || echo "unknown")"
    local commit_msg="chore: sync from ${hostname} on $(date '+%Y-%m-%d %H:%M')"

    git add -A
    git commit -m "$commit_msg"
    log_ok "Committed: ${commit_msg}"

    git push -u origin HEAD
    log_ok "Pushed to remote"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    local mode="${1:-both}"

    case "$mode" in
        --pull) do_pull ;;
        --push) do_push ;;
        --help|-h) usage; exit 0 ;;
        both)
            do_pull
            echo ""
            do_push
            ;;
        *)
            log_error "Unknown option: $mode"
            usage
            exit 1
            ;;
    esac
}

main "$@"
