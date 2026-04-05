# dotfiles

Personal development environment managed as modular dotfiles.  
Supports Ubuntu (primary) and macOS.

---

## Quick Start

### New machine (one command)

```bash
git clone https://github.com/jinwoo-choiter/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

`bootstrap.sh` will:
1. Install essential packages (`git`, `curl`, `vim`, …)
2. Run `install.sh` (all modules)
3. Install system packages via `scripts/packages.sh`
4. Install VSCode extensions via `scripts/vscode-ext.sh` (if `code` CLI is found)

### Install modules only

```bash
# All modules
./install.sh

# Specific modules
./install.sh bash git
```

### Sync changes

```bash
./sync.sh          # pull remote changes, then push local changes
./sync.sh --pull   # pull only (repo → local)
./sync.sh --push   # push only (local → repo)
```

---

## Directory Layout

```
dotfiles/
├── bootstrap.sh          # New-machine setup (run once)
├── install.sh            # Module installer
├── sync.sh               # Bidirectional sync
├── .gitignore
│
├── lib/
│   └── utils.sh          # Shared functions (log, OS detect, symlink, append, copy)
│
├── scripts/
│   ├── packages.sh       # System package installer (apt / brew)
│   └── vscode-ext.sh     # VSCode extension bulk-installer
│
└── modules/
    ├── bash/             # .bashrc (append), .bash_aliases (symlink)
    ├── git/              # .gitconfig (symlink)
    ├── ssh/              # ~/.ssh/config (copy, chmod 600)
    ├── terminator/       # ~/.config/terminator/config (symlink)
    └── vscode/           # settings.json, keybindings.json (symlink), extensions.txt
```

---

## Install Modes

Each entry in `install.conf` uses one of three modes:

| Mode | Behaviour |
|------|-----------|
| `symlink` | Creates a symlink. Edits to the file are immediately reflected in the repo. |
| `append` | Appends content wrapped in idempotent markers. Re-running replaces the block. |
| `copy` | Copies the file. SSH config gets `chmod 600` automatically. |

### `install.conf` format

```
# mode    source              target                   [os=linux|mac]
symlink   gitconfig           ~/.gitconfig
append    bashrc              ~/.bashrc
copy      ssh_config          ~/.ssh/config
symlink   settings.json       ~/.config/Code/User/settings.json    os=linux
```

- Blank lines and `#` comments are ignored.
- `~` in target is expanded to `$HOME`.
- `os=` is optional; omit for all platforms.

---

## Adding a New Module

1. Create `modules/<name>/`
2. Add your config file(s) inside it
3. Create `modules/<name>/install.conf` with the install entries
4. Run `./install.sh <name>` to test

No changes to any existing script are needed.

---

## Sensitive / Local Overrides

Files matching `*.local` are git-ignored. Use them for machine-specific settings:

| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | Your name, email, GPG key |
| `~/.bashrc.local` | Machine-specific env vars, PATH additions |
| `~/.ssh/config.local` | Host-specific SSH entries |

The managed configs automatically `include`/`source` these files when present.

---

## Log Output

```
[OK]    symlink /path/to/repo/modules/git/gitconfig → ~/.gitconfig
[SKIP]  symlink already up-to-date: ~/.bash_aliases
[ERROR] source not found: modules/foo/bar
```

Colors: `[OK]` green · `[SKIP]` yellow · `[ERROR]` red
