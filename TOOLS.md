
# Tools in this Bash Configuration

This document lists the tools referenced or encouraged by `bashrc`, with short usage notes and examples so you can get productive quickly.

For expanded scenarios, testing steps, and quick verification commands see `GUIDE.md`.

Format: **Tool** — short description

- **vim** — text editor. Usage: `vim <file>`.
- **fzf** — fuzzy finder. Examples:
  - `ff` (defined in `bashrc`) opens fzf to pick a file and edit it.
  - `fcd` fuzzy-cds into a selected directory.
  - Use `ctrl-r` for history search.

- **eza** — modern `ls` replacement with icons. Aliases: `ls`, `ll`, `la` map to `eza` when available. Usage: `eza -la`
- **bat / batcat** — syntax-highlighting `cat`. Aliases: `cat` maps to `bat --paging=never` where available. Usage: `cat file.json` (uses `bat`).
- **btop** — modern `top`. Aliases: `top` and `htop` map to `btop`.
- **zoxide** — smart `cd` replacement. `bashrc` initializes it and aliases `cd` to `z`. Usage: `z <snippet>` to jump.
- **tmux** — terminal multiplexer. Start with `tmux` or `tmux new -s session`.
- **ripgrep (rg)** — fast recursive search. Usage: `rg "pattern"`.
- **fd-find (fd / fdfind)** — fast file finder. Usage: `fd <name>`.
- **delta (git-delta)** — prettier `git diff`. Configure with `git config --global core.pager "delta"`.
- **ncdu** — disk usage analyzer. Usage: `ncdu /path`.

- **jq** — JSON processor. Usage: `jq . file.json`.
- **yq** — YAML processor (Python or go variant). Usage: `yq eval . file.yaml`.
- **httpie (http)** — friendly HTTP client. Usage: `http GET https://example.com`.
- **make** — build tool. Usage: `make`.
- **python3-pip / python3-venv / python3-dev** — Python tooling. Create venv: `python3 -m venv .venv` then `source .venv/bin/activate`.
- **nvm** — Node version manager (installer suggested). After installing: `nvm install --lts`.

- **docker / docker-compose** — container runtime. After install, add your user to `docker` group to run without sudo. Commands: `docker ps`, `docker compose up -d`.
- **lazydocker** — TUI for Docker. Run: `lazydocker`.
- **kubectl** — Kubernetes CLI. Usage: `kubectl get pods`.
- **helm** — Kubernetes package manager. Usage: `helm repo add stable ...` and `helm upgrade --install`.
- **k9s** — Kubernetes TUI. Run: `k9s`.
- **kubectx / kubens** — switch contexts / namespaces. Usage: `kubectx <context>` / `kubens <namespace>`.

- **terraform** — IaC tool. Usage: `terraform init && terraform plan`.
- **ansible** — configuration management. Usage: `ansible-playbook site.yml`.

- **aws-cli v2** — AWS CLI (optional). Usage: `aws s3 ls`.
- **gcloud** — Google Cloud CLI (optional, not auto-installed by default).

- **lazygit** — TUI for git. Run: `lazygit`.

- **gh** — GitHub CLI. Create PRs, issues and interact with GitHub from the terminal. Usage: `gh pr create`, `gh issue list`.
- **direnv** — Per-project environment loader. Add `eval "$(direnv hook bash)"` to your shell and use `.envrc` files per project.
- **asdf** — Universal version manager for node/ruby/python/go/etc. Usage: `asdf plugin-add nodejs && asdf install nodejs lts`.
- **tldr** — Concise community examples for CLI commands. Usage: `tldr tar`.
- **podman** — Daemonless container engine; rootless-friendly alternative to Docker. Usage: `podman ps`, `podman run --rm -it alpine sh`.
- **kind** — Run local Kubernetes clusters in Docker for development/testing. Usage: `kind create cluster`.
- **krew** — `kubectl` plugin manager. After installing `krew`, install plugins like `kubectl krew install ctx`.

- **OpenShift CLI (oc)** — CLI for OpenShift clusters. The installer can optionally download the official OpenShift client tarball and install the `oc` binary to `/usr/local/bin`. Quick test: `oc version --client`.

- **Postman** — GUI API client. The installer can optionally install Postman via `snap` or tarball. Launch via application menu or `postman` binary if installed.
- **VLC** — Media player available via apt or snap. Launch via `vlc`.
- **AnyDesk** — Remote desktop client. The installer can optionally add AnyDesk's APT repo and install the `anydesk` package. Quick test: `anydesk --version` and launch from desktop.
- **Termius** — GUI + CLI SSH client with host management and snippets. Installer: optional via `snap install termius-app --classic` when `snap` is available. Manual downloads available from https://www.termius.com/download

- **starship** — optional prompt engine. If you install and enable it, replace the prompt block in `~/.bashrc` with `eval "$(starship init bash)"`.

- **neofetch** — simple system info banner shown on shell startup if present. `bashrc` runs `neofetch` automatically (with a blank margin line). Usage: `neofetch`.

# Additional tools added by the installer

- **autojump** — quickly jump to frequently used directories. Usage: `autojump <partial>` or use `j <partial>` if aliased.
- **entr** — run arbitrary commands when files change (useful for rebuilds/tests). Example: `ls **/*.py | entr -r pytest`.
- **thefuck** — suggests fixes for mistyped shell commands. After install, run `thefuck --alias` to add alias.
- **tig** — ncurses-based git repository browser. Usage: `tig` or `tig status`.
# **OpenJDK** — multiple Java runtimes may be installed by the installer.
# The installer can offer to install OpenJDK 8, 11, 17 and 21 (packages: `openjdk-8-jdk`, `openjdk-11-jdk`, `openjdk-17-jdk`, `openjdk-21-jdk`).
# Quick test: `java -version` and `javac -version` — use `update-alternatives` to switch defaults (see below).
# To switch the system default Java/Javac after installing multiple JDKs:
# ```bash
# sudo update-alternatives --config java
# sudo update-alternatives --config javac
# ```
# thefuck: installer behavior
The `bashrc` and `install.sh` were updated to attempt to enable the `thefuck` alias automatically when the binary is present. A guarded `eval "$(thefuck --alias)"` entry is added to the provided `bashrc` so the alias is active in interactive shells.

- **wps-office** — optional Microsoft-compatible office suite (GUI).
  - Installer: `install.sh` prompts `Install WPS Office (optional)? [y/N]`. If accepted and LibreOffice/OpenOffice is detected, the installer asks whether to remove those packages before installing WPS to avoid conflicts. If `wps-office` isn't available in `apt` the installer will warn and provide the official download URL.
- **git-crypt** — transparent file encryption for git repositories. Usage: `git-crypt init`.
- **rbenv / pyenv** — language version managers (Ruby / Python). Installer adds clones and prints instructions to source in `~/.bashrc`.
- **neovim (nvim)** — modern Vim fork. Usage: `nvim <file>`.
- **micro** — simple terminal-based editor. Usage: `micro <file>`.
- **chromium** — Chromium browser (prompted install; skipped if other browsers present).
- **keepassxc** — cross-platform password manager GUI. Usage: launch from applications menu.
- **taskwarrior** — command-line task manager. Usage: `task add Buy milk`.

Krew plugin recommendations
- `ctx` — quick context switching helper (similar to `kubectx`).
- `ns` — namespace switching helper (similar to `kubens`).
- `konfig` — view and manage k8s config.
- `view-secret` — safely view secrets in different formats.
- `who-can` — RBAC utility to check who can perform actions.

Tips
- Many of the modern tools (`eza`, `bat`, `fd`, `ripgrep`) are used as drop-in replacements via aliases in `bashrc` — you can revert to system defaults by removing or commenting aliases in `~/.bashrc.local`.
- If a tool fails to install during `install.sh`, re-run the script after fixing network or repo issues; the script will skip already-installed tools.
