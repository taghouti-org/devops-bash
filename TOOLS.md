# Tools in this Bash Configuration

This document lists the tools referenced or encouraged by `bashrc`, with short usage notes and examples so you can get productive quickly.

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

- **Postman** — GUI API client. The installer can optionally install Postman via `snap` or tarball. Launch via application menu or `postman` binary if installed.
- **VLC** — Media player available via apt or snap. Launch via `vlc`.

- **starship** — optional prompt engine. If you install and enable it, replace the prompt block in `~/.bashrc` with `eval "$(starship init bash)"`.

- **neofetch** — simple system info banner shown on shell startup if present. `bashrc` runs `neofetch` automatically (with a blank margin line). Usage: `neofetch`.

Krew plugin recommendations
- `ctx` — quick context switching helper (similar to `kubectx`).
- `ns` — namespace switching helper (similar to `kubens`).
- `konfig` — view and manage k8s config.
- `view-secret` — safely view secrets in different formats.
- `who-can` — RBAC utility to check who can perform actions.

If you'd like, I can expand any of these entries with example commands and common flags.

Tips
- Many of the modern tools (`eza`, `bat`, `fd`, `ripgrep`) are used as drop-in replacements via aliases in `bashrc` — you can revert to system defaults by removing or commenting aliases in `~/.bashrc.local`.
- If a tool fails to install during `install.sh`, re-run the script after fixing network or repo issues; the script will skip already-installed tools.

Want detailed usage snippets for any specific tool? Tell me which ones and I will expand their sections with commands and common flags.