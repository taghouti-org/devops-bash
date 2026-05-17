# DevOps Bash Toolbox

A small collection of shell utilities, aliases and an installer to bootstrap a DevOps-friendly environment on Ubuntu 24.04 (x86_64).

This repository contains:

- `bashrc` — opinionated, feature-rich bash configuration (intended to be installed to `~/.bashrc`).
- `install.sh` — installer script that copies `bashrc` into place and installs recommended CLI tools.

## Goals

- Provide a ready-to-use prompt, useful aliases, and handy functions for day-to-day DevOps work.
- Install modern replacements for core utilities (e.g. `eza`, `bat`, `btop`, `fd`, `rg`).
- Optionally install cloud CLIs and developer tooling (Docker, kubectl, helm, terraform, ansible, etc.).

## Quick install

Run the installer from this directory:

```bash
cd /path/to/devops-bash
./install.sh
```

The installer will:
- Back up any existing `~/.bashrc` to `~/.bashrc.backup.YYYYMMDD_HHMMSS`
- Copy `bashrc` from this repo to `~/.bashrc`
- Install a curated set of packages via `apt` (uses `sudo` when not run as root)

The installer prompts for optional steps like AWS CLI and Starship.

## What it installs (high level)

- Terminal utilities: `vim`, `nvim`, `fzf`, `eza`, `bat`, `btop`, `zoxide`, `tmux`, `ripgrep`, `fd-find`, `delta`, `ncdu`, `autojump`, `entr`, `thefuck`, `tig`
- Dev tools: `jq`, `yq`, `httpie`, `make`, Python extras, `nvm` (installer), `pyenv`, `rbenv`, `gh`, `direnv`, `asdf`, `tldr`, `lazygit`, `tig`, `git-crypt`
- DevOps / Cloud: `docker`, `lazydocker`, `kubectl`, `helm`, `k9s`, `kubectx/kubens`, `krew`, `kind`, `podman`, `terraform`, `ansible`
- Optional: `aws-cli`, `starship` prompt, `neofetch` (welcome banner), GUI apps (VSCode, Chrome/Chromium, Postman, VLC, keepassxc)

### New additions and notes
- Optional GUI / desktop apps: `Postman`, `VLC`, `VSCode`, `Google Chrome` (installed only if requested).
- Developer utilities: `gh` (GitHub CLI), `direnv`, `asdf`, `tldr`, `kind`, `podman`, and `krew` (kubectl plugin manager).
- The installer includes an optional `krew` flow and can install recommended krew plugins (`ctx`, `ns`, `konfig`, `view-secret`, `who-can`, `kc`).
- The installer avoids launching GUI applications when probing for installed tools (so `postman --version` will not be executed).
- Non-interactive flags:
	- `-y` / `--yes` — assume yes for prompts.
	- `--cleanup` — automatically remove installer backups/logs at end.

Note: The installer checks for existing equivalents and will skip installing tools that are already present to avoid duplicate functionality.

## Welcome banner

This setup uses `neofetch` to show a welcome banner (if installed). The `install.sh` will install `neofetch` and `bashrc` will call it on interactive shell startup if present.

## Customization

- Edit `bashrc` in this repo to change colors, prompt layout, or enable/disable features.
- Local, host-specific tweaks can go into `~/.bashrc.local` or `~/.bash_aliases` (both are loaded if present).

## Uninstall / Revert

To revert to your previous `~/.bashrc` (if backed up by the installer):

```bash
mv ~/.bashrc.backup.* ~/.bashrc
source ~/.bashrc
```

To remove packages installed by the script, use `apt remove`/`purge` or your package manager — the script intentionally does not include an automated uninstall.

## Troubleshooting

- If a package fails to install, check network access and try again. Re-run the installer to retry failed components.
- For debugging, open `install.sh` and inspect the `INSTALLED`, `SKIPPED`, and `FAILED` arrays displayed at the end of the run.

## Contributing

PRs welcome. Keep changes focused and consistent with the existing style. If adding packages, follow the `check_tool` / `try` pattern used in `install.sh`.

## License

MIT — see LICENSE (not included by default).
