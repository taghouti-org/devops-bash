# DevOps Bash Toolbox — Quick Guide

This guide gives a short, practical usage note and quick test for each tool installed by `install.sh`. Use the "Test" commands to verify installations and try the suggested scenarios to evaluate usefulness.

---

## Terminal utilities

- vim / nvim
  - When to use: editing configs, quick edits on remote hosts, or when you prefer modal editing.
  - Quick test: `vim --version` or `nvim --version`
  - Try: open `nvim ~/.bashrc` and make a small change then save.

- fzf
  - When to use: fuzzy interactive selection for files, history, and more (fast keyboard-driven navigation).
  - Quick test: `printf "one\ntwo\nthree\n" | fzf --version` (or just run `fzf`).
  - Try: `ls -a | fzf` and pick an item.

- eza
  - When to use: modern `ls` replacement with colors and icons.
  - Quick test: `eza --version` or `eza -la` in a directory.
  - Try: `eza -la --icons` (confirm icons show when a Nerd font is used).

- bat
  - When to use: syntax-highlighted `cat`, great for reading source files.
  - Quick test: `bat --version` (or `batcat --version` on some distros).
  - Try: `bat README.md`.

- btop
  - When to use: interactive process/monitoring with nice UI.
  - Quick test: `btop --version`.
  - Try: run `btop` and observe CPU / processes.

- zoxide / autojump
  - When to use: jump to frequently-used directories using partial names.
  - Quick test: if `zoxide` present: `zoxide query` or run `autojump --help`.
  - Try: `cd /tmp && mkdir -p /tmp/foo/bar && cd ~; z tmp` (use zoxide learning) or use `j bar` for autojump.

- tmux
  - When to use: terminal multiplexing, persistent sessions on remote servers.
  - Quick test: `tmux -V`.
  - Try: `tmux new -s test` then detach with `Ctrl-b d` and reattach `tmux attach -t test`.

- ripgrep (rg)
  - When to use: very fast recursive search of codebases.
  - Quick test: `rg --version` and `rg TODO`.
  - Try: `rg "def main"` in a Python repo.

- fd
  - When to use: fast file finder replacement for `find` with sensible defaults.
  - Quick test: `fd --version` or `fd README`.
  - Try: `fd -e md` to list Markdown files.

- delta
  - When to use: improved `git diff` pager for readable diffs.
  - Quick test: `git --no-pager diff` in a repo with changes (or `delta --version`).
  - Try: `git diff | delta`.

- ncdu
  - When to use: inspect disk usage interactively to find large directories.
  - Quick test: `ncdu --version` then `ncdu /tmp`.

- tldr
  - When to use: quick, example-driven manpages for common commands.
  - Quick test: `tldr tar`.
  - Try: `tldr find`.

- entr
  - When to use: re-run commands when files change (useful for tests/build loops).
  - Quick test: `echo test | entr --version` or `ls *.py | entr -p echo changed`.
  - Try: `ls *.py | entr -r pytest`.

- thefuck
  - When to use: get suggestions for fixing mistyped commands.
  - Quick test: `thefuck --version` and follow post-install alias instructions (`eval $(thefuck --alias)`).
  - Try: run an invalid command like `gti status` then run `fuck`.
- thefuck
  - When to use: get suggestions for fixing mistyped commands.
  - Note: the Ubuntu `thefuck` apt package can be outdated or broken on newer Python versions (ModuleNotFoundError: No module named 'imp').
  - Recommended install: use `pipx` for isolated installs:
    ```bash
    # install pipx (if missing)
    sudo apt-get install -y pipx python3-venv
    pipx ensurepath
    pipx install thefuck
    ```
    Fallback: `python3 -m pip install --user thefuck` (ensure `~/.local/bin` is on `PATH`).
  - Quick test: `thefuck --version` and add the alias with `eval "$(thefuck --alias)"`.
  - Try: run an invalid command like `gti status` then run `fuck` to apply the suggested fix.
  
  Note: the installer now attempts to enable `thefuck` for the current shell automatically when it installs or detects the binary, and also adds a guarded `eval "$(thefuck --alias)"` to the repo `bashrc` so the alias persists for interactive shells.

- tig
  - When to use: terminal-based Git repository browser.
  - Quick test: `tig --version` and run `tig` inside a git repo.

- git-crypt
  - When to use: transparently encrypt files in a git repo (secrets management for repos).
  - Quick test: `git-crypt --version`.
  - Try: in a repo, `git-crypt init` then follow docs to lock files.

- micro
  - When to use: simple, user-friendly terminal editor for quick edits.
  - Quick test: `micro --version`.
  - Try: `micro test.txt` and edit.

- neovim (nvim)
  - When to use: modern Vim with extended plugin ecosystem.
  - Quick test: `nvim --version`.

- taskwarrior
  - When to use: command-line task manager and todo lists.
  - Quick test: `task --version` then `task add test` and `task list`.

---

## Dev tools

- jq
  - When to use: parse and transform JSON on the command line.
  - Quick test: `echo '{"a":1}' | jq .`.
  - Try: `cat package.json | jq '.name'`.

- yq
  - When to use: YAML querying and editing (similar to jq for YAML).
  - Quick test: `yq eval '.' some.yaml`.

- httpie (http)
  - When to use: human-friendly HTTP client for inspecting APIs.
  - Quick test: `http --version` and `http GET https://httpbin.org/get`.

- make
  - When to use: run build/test recipes.
  - Quick test: `make --version` and run a Makefile target.

- nvm
  - When to use: manage Node.js versions per project.
  - Quick test: `command -v nvm` (or `source ~/.bashrc` then `nvm --version`).
  - Try: `nvm install --lts && node --version`.

- pyenv / rbenv
  - When to use: manage multiple Python / Ruby versions for projects.
  - Quick test: `pyenv --version` / `rbenv --version` (after sourcing their environment lines in your shell).

- lazygit
  - When to use: TUI for common Git operations (staging, commits, branches).
  - Quick test: `lazygit --version` and run `lazygit` inside a repo.

- gh (GitHub CLI)
  - When to use: interact with GitHub (create PRs, issues, view CI) from terminal.
  - Quick test: `gh --version` and `gh auth status`.
  - Try: `gh repo view --web`.

- direnv
  - When to use: per-directory environment variable loading (`.envrc`).
  - Quick test: `direnv --version` and `eval "$(direnv hook bash)"`.
  - Try: create `.envrc` with `export FOO=bar`, run `direnv allow` and `echo $FOO`.

- asdf
  - When to use: polyglot version manager for many runtimes (node, ruby, python, etc.).
  - Quick test: `asdf --version` and `asdf plugin-list`.

- tldr
  - (Covered above in Terminal utilities.)

---

## DevOps / Cloud

- docker
  - When to use: container runtime for development and CI.
  - Quick test: `docker --version` and `docker run --rm hello-world`.

- lazydocker
  - When to use: TUI to inspect containers, logs, and compose.
  - Quick test: `lazydocker --version` and run `lazydocker` while Docker is running.

- podman
  - When to use: rootless container runtime alternative to Docker.
  - Quick test: `podman --version` and `podman run --rm alpine uname -a`.

- kubectl
  - When to use: Kubernetes CLI for cluster interactions.
  - Quick test: `kubectl version --client`.

- helm
  - When to use: package manager for Kubernetes charts.
  - Quick test: `helm version` and `helm repo list`.

- k9s
  - When to use: interactive TUI for Kubernetes cluster browsing.
  - Quick test: `k9s version` and run `k9s` against a kubeconfig.

- kubectx / kubens
  - When to use: fast context and namespace switching.
  - Quick test: `kubectx --help` / `kubens --help`.

- krew
  - When to use: manage `kubectl` plugins (install extra tooling).
  - Quick test: `kubectl krew` or `~/.krew/bin/kubectl-krew version` and `kubectl krew list`.

- kind
  - When to use: local Kubernetes clusters for development/testing.
  - Quick test: `kind --version` and `kind create cluster --name test` (requires Docker).

- terraform
  - When to use: infrastructure as code provisioning.
  - Quick test: `terraform version` and `terraform init` in a sample module.

- ansible
  - When to use: configuration management and orchestration.
  - Quick test: `ansible --version` and create a small `hosts` and run `ansible -m ping all`.

- krew plugins (ctx, ns, konfig, view-secret, who-can)
  - When to use: convenience utilities for Kubernetes workflows (context switching, secrets viewing, RBAC checks).
  - Quick test: after `kubectl krew install <plugin>`, run `kubectl <plugin> --help`.

---

## GUI / Desktop

- VSCode / code
  - When to use: full-fledged graphical editor/IDE.
  - Quick test: `code --version` (when installed) or launch from desktop.

- Google Chrome / Chromium
  - When to use: browser for web apps and testing.
  - Quick test: `google-chrome --version` or `chromium-browser --version`.

- Postman
  - When to use: GUI API client for exploring REST/GraphQL endpoints.
  - Quick test: launch via desktop menu; CLI test isn't reliable because GUI may block.

- VLC
  - When to use: media playback.
  - Quick test: `vlc --version` and open a media file.

- WPS Office
  - When to use: lightweight, MS Office-compatible desktop suite for word processing, spreadsheets and presentations.
  - Installer behavior: `install.sh` offers WPS as an optional install. If `LibreOffice` or `OpenOffice` is present the installer will prompt to remove them first to avoid conflicts. If `wps-office` is not available via `apt`, the installer warns and points you to https://www.wps.com/linux for manual installation.
  - Quick test: after installation, run `wps` (or use your desktop menu) to launch WPS.

- keepassxc
  - When to use: manage passwords locally with a GUI.
  - Quick test: launch via desktop menu; `keepassxc --version` may print version.

---

## Prompt & Visuals

- starship
  - When to use: fast, custom prompt; replace PS1 for nicer prompts.
  - Quick test: `starship --version` and run `eval "$(starship init bash)"`.

- neofetch
  - When to use: show system info in shell banner.
  - Quick test: `neofetch`.

- Nerd / Patched fonts
  - When to use: to render icons correctly in `eza` and many prompts.
  - Quick test: set your terminal font to the installed Nerd font and run `eza --icons` or `neofetch`.

---

## Quick verification script

You can run the following snippet to smoke-test many CLI tools quickly:

```bash
#!/usr/bin/env bash
set -e
TOOLS=(vim nvim fzf eza bat btop zoxide tmux rg fd delta ncdu tldr autojump entr thefuck tig git-crypt micro python3 pip3 docker kubectl helm k9s kubectx kind terraform ansible gh direnv asdf lazygit)
for t in "${TOOLS[@]}"; do
  if command -v "$t" &>/dev/null; then
    printf "%-15s OK\n" "$t"
  else
    printf "%-15s MISSING\n" "$t"
  fi
done
```

Run it and inspect MISSING entries to decide which installers to re-run.

---

If you want expanded scenarios and examples for a subset of tools (e.g., common `kubectl` workflows, `docker` compose examples, or `git-crypt` usage), tell me which ones and I'll expand those sections with step-by-step examples and small demo commands.
