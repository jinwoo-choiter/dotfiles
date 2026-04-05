#!/usr/bin/env bash
# lib/utils.sh — shared utilities for dotfiles install/sync scripts

# ─── Colours ──────────────────────────────────────────────────────────────────
_CLR_GREEN='\033[0;32m'
_CLR_YELLOW='\033[1;33m'
_CLR_RED='\033[0;31m'
_CLR_RESET='\033[0m'

log_ok()    { echo -e "${_CLR_GREEN}[OK]${_CLR_RESET}    $*"; }
log_skip()  { echo -e "${_CLR_YELLOW}[SKIP]${_CLR_RESET}  $*"; }
log_error() { echo -e "${_CLR_RED}[ERROR]${_CLR_RESET} $*" >&2; }

# ─── OS Detection ─────────────────────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "mac"   ;;
        *)       echo "unknown" ;;
    esac
}

# ─── Backup ───────────────────────────────────────────────────────────────────
# backup_if_exists <path>
# Moves an existing file/symlink to <path>.backup (or <path>.backup.<ts> if
# the .backup file already exists). Does nothing if <path> does not exist.
backup_if_exists() {
    local target="$1"
    [[ -e "$target" || -L "$target" ]] || return 0

    local backup="${target}.backup"
    if [[ -e "$backup" || -L "$backup" ]]; then
        backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
    fi
    mv "$target" "$backup"
    log_skip "Backed up existing $(basename "$target") → $(basename "$backup")"
}

# ─── do_symlink ───────────────────────────────────────────────────────────────
# do_symlink <absolute_src> <target>
do_symlink() {
    local src="$1"
    local target="$2"

    # Already the correct symlink — nothing to do
    if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
        log_skip "symlink already up-to-date: $target"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    backup_if_exists "$target"
    ln -s "$src" "$target"
    log_ok "symlink $src → $target"
}

# ─── do_append ────────────────────────────────────────────────────────────────
# do_append <absolute_src> <target> <module_name>
# Idempotent: wraps content between marker lines. Re-running replaces the block.
do_append() {
    local src="$1"
    local target="$2"
    local module="$3"
    local begin_marker="# === BEGIN dotfiles:${module} ==="
    local end_marker="# === END dotfiles:${module} ==="

    mkdir -p "$(dirname "$target")"
    touch "$target"

    local content
    content="$(cat "$src")"

    # Remove existing block (if any) then re-append
    if grep -qF "$begin_marker" "$target" 2>/dev/null; then
        # Use a temp file to avoid in-place issues across platforms
        local tmpfile
        tmpfile="$(mktemp)"
        awk -v begin="$begin_marker" -v end="$end_marker" '
            $0 == begin { skip=1; next }
            $0 == end   { skip=0; next }
            !skip        { print }
        ' "$target" > "$tmpfile"
        mv "$tmpfile" "$target"
        log_skip "Replaced existing dotfiles:${module} block in $target"
    fi

    {
        echo ""
        echo "$begin_marker"
        echo "$content"
        echo "$end_marker"
    } >> "$target"

    log_ok "append $src → $target"
}

# ─── do_copy ──────────────────────────────────────────────────────────────────
# do_copy <absolute_src> <target>
do_copy() {
    local src="$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"
    backup_if_exists "$target"
    cp "$src" "$target"

    # Preserve restrictive permissions for SSH config
    if [[ "$target" == *"/.ssh/"* ]]; then
        chmod 600 "$target"
        chmod 700 "$(dirname "$target")" 2>/dev/null || true
    fi

    log_ok "copy $src → $target"
}

# ─── parse_and_apply ──────────────────────────────────────────────────────────
# parse_and_apply <conf_file> <module_dir> <module_name>
# Reads install.conf and dispatches each entry to the appropriate handler.
parse_and_apply() {
    local conf_file="$1"
    local module_dir="$2"
    local module_name="$3"
    local current_os
    current_os="$(detect_os)"

    local ok_count=0 skip_count=0 err_count=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Strip comments and blank lines
        line="${line%%#*}"
        line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [[ -z "$line" ]] && continue

        # Parse fields: mode  source  target  [os=linux|mac]
        local mode src_rel target os_filter
        read -r mode src_rel target os_filter <<< "$line"

        # Expand ~ in target
        target="${target/#\~/$HOME}"

        # OS filter
        if [[ -n "$os_filter" ]]; then
            local required_os="${os_filter#os=}"
            if [[ "$current_os" != "$required_os" ]]; then
                log_skip "[$module_name] $src_rel (requires os=$required_os, got $current_os)"
                (( skip_count++ )) || true
                continue
            fi
        fi

        local src_abs="${module_dir}/${src_rel}"

        if [[ ! -f "$src_abs" ]]; then
            log_error "[$module_name] source not found: $src_abs"
            (( err_count++ )) || true
            continue
        fi

        case "$mode" in
            symlink)
                if do_symlink "$src_abs" "$target"; then
                    (( ok_count++ )) || true
                else
                    (( err_count++ )) || true
                fi
                ;;
            append)
                if do_append "$src_abs" "$target" "$module_name"; then
                    (( ok_count++ )) || true
                else
                    (( err_count++ )) || true
                fi
                ;;
            copy)
                if do_copy "$src_abs" "$target"; then
                    (( ok_count++ )) || true
                else
                    (( err_count++ )) || true
                fi
                ;;
            *)
                log_error "[$module_name] unknown mode: $mode"
                (( err_count++ )) || true
                ;;
        esac
    done < "$conf_file"

    # Export counters so install.sh can accumulate them
    _LAST_OK=$ok_count
    _LAST_SKIP=$skip_count
    _LAST_ERR=$err_count
}
