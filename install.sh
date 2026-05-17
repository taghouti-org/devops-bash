#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║          DevOps Toolbox Installer — Ubuntu 24.04 x86_64         ║
# ║   Installs everything needed to make your .bashrc fully alive   ║
# ╚══════════════════════════════════════════════════════════════════╝
set -euo pipefail

# Ensure commonly referenced variables exist to avoid 'set -u' failures
SUDO=""
PREINSTALL_BACKUP=""
TMP_SHIM_DIR=""
DEBUG=0
# When quiet, pass '-qq' to apt-get; when DEBUG=1 we clear this so apt prints output
APT_QUIET='-qq'

# ── Colors ────────────────────────────────────────────────────────
R=$'\033[0m'
BOLD=$'\033[1m'
if [[ -t 0 ]]; then
    echo ""
fi
GREEN=$'\033[0;32m'
BGREEN=$'\033[1;32m'
CYAN=$'\033[0;36m'
BCYAN=$'\033[1;36m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
GREY=$'\033[38;5;244m'
NEON=$'\033[38;5;45m'
PINK=$'\033[38;5;205m'

# ── Helpers ───────────────────────────────────────────────────────
info()    { echo -e "${BCYAN}  ❯${R} $*"; }
success() { echo -e "${BGREEN}  ✔${R} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${R}  $*"; }
error()   { echo -e "${RED}  ✘${R} $*"; }
section() { echo -e "\n${NEON}${BOLD}━━━ $* ━━━${R}"; }

# Track what was installed vs skipped
INSTALLED=()
SKIPPED=()
FAILED=()

mark_installed() { INSTALLED+=("$1"); }
mark_skipped()   { SKIPPED+=("$1"); }
mark_failed()    { FAILED+=("$1"); }

# Run a command, capture failure without exiting
try() {
    local label="$1"; shift
    if [[ "${DEBUG:-0}" -eq 1 ]]; then
        if "$@"; then
            success "$label installed"
            mark_installed "$label"
        else
            error "$label FAILED — check manually"
            mark_failed "$label"
        fi
    else
        if "$@" &>/dev/null; then
            success "$label installed"
            mark_installed "$label"
        else
            error "$label FAILED — check manually"
            mark_failed "$label"
        fi
    fi
}

# Run a shell command string; hide output unless DEBUG is enabled
run() {
    local cmd="$*"
    if [[ "${DEBUG:-0}" -eq 1 ]]; then
        eval "$cmd"
    else
        eval "$cmd" &>/dev/null
    fi
}

# Check if a binary exists
has() { command -v "$1" &>/dev/null; }

# (No GUI app pre-checks here — avoid launching GUI apps when probing.)

# CLI options
ASSUME_YES=0
CLEANUP_AUTO=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--debug)
            DEBUG=1; shift ;;
        -y|--yes)
            ASSUME_YES=1; shift ;;
        --cleanup|--remove-backups)
            CLEANUP_AUTO=1; shift ;;
        --)
            shift; break ;;
        *)
            break ;;
    esac
done

# If debug requested, make apt verbose and enable xtrace for easier debugging
if [[ "${DEBUG:-0}" -eq 1 ]]; then
    APT_QUIET=''
    # Colorize xtrace prefix so debug command traces stand out
    PS4='${YELLOW}+${R} '
    export PS4
    set -x
fi

# check_tool NAME [BINARY]
#   If the tool is found: print path + version, mark skipped, return 0 (→ skip install)
#   If not found: return 1 (→ proceed with install)
check_tool() {
    local label="$1"
    local bin="${2:-$1}"   # default binary name == label
    local bin_path ver

    # If caller passed alternate binary names, they will be tried below.
    bin_path=$(command -v "$bin" 2>/dev/null) || {
        # also try common alt names passed as extra args
        shift 2 2>/dev/null || shift 1
        for alt in "$@"; do
            bin_path=$(command -v "$alt" 2>/dev/null) && bin="$alt" && break
        done
    }

    if [[ -n "$bin_path" ]]; then
        # Avoid executing GUI app binaries when probing for versions (they may launch)
        NO_VERSION_EXEC=(postman code "google-chrome" chrome firefox vlc)
        skip_ver=0
        for p in "${NO_VERSION_EXEC[@]}"; do
            if [[ "$bin" == "$p" || "$bin_path" == *"/$p" ]]; then
                skip_ver=1; break
            fi
        done
        if [[ "$skip_ver" -eq 0 ]]; then
            # Try to get a version string; suppress errors gracefully
            ver=$( "$bin" --version 2>/dev/null \
                || "$bin" version 2>/dev/null \
                || "$bin" -v 2>/dev/null \
                || echo "" ) 
        else
            ver=""
        fi
        ver=$(echo "$ver" | head -1 | sed 's/^[[:space:]]*//' | cut -c1-60)
        if [[ -n "$ver" ]]; then
            echo -e "${GREY}  ↷  ${BOLD}${label}${R}${GREY} already installed — skipping${R}"
            echo -e "${GREY}       cmd : ${bin_path}${R}"
            echo -e "${GREY}       ver : ${ver}${R}"
        else
            echo -e "${GREY}  ↷  ${BOLD}${label}${R}${GREY} already installed — skipping${R}"
            echo -e "${GREY}       cmd : ${bin_path}${R}"
        fi
        mark_skipped "$label"
        return 0   # already installed → caller should skip
    fi
    return 1       # not found → caller should install
}

# ── Root check ────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    SUDO="sudo"
    warn "Not running as root — will use sudo for system installs"
else
    SUDO=""
fi

# Detect whether this script is being sourced or executed
IS_SOURCED=0
if [ "${BASH_SOURCE[0]:-}" != "${0:-}" ]; then
    IS_SOURCED=1
fi
# Temporarily protect existing ~/.bashrc from being sourced during the
# installer. Move it out of the way early so any child shells won't auto-run
# user startup logic (e.g. starting tmux). It will be restored on abort.
if [[ -f "$HOME/.bashrc" ]]; then
    ORIGINAL_BASHRC="$HOME/.bashrc"
    PREINSTALL_BACKUP="$HOME/.bashrc.preinstall.$(date +%Y%m%d_%H%M%S)"
    mv "$ORIGINAL_BASHRC" "$PREINSTALL_BACKUP" 2>/dev/null || true
    success "Temporarily moved existing ~/.bashrc → ${PREINSTALL_BACKUP}"

    restore_on_exit() {
        if [[ -f "${PREINSTALL_BACKUP}" && ! -f "$HOME/.bashrc" ]]; then
            mv -f "${PREINSTALL_BACKUP}" "$HOME/.bashrc" 2>/dev/null || true
            echo -e "${YELLOW}Installer aborted — original ~/.bashrc restored${R}"
        fi
    }
    trap restore_on_exit EXIT
else
    PREINSTALL_BACKUP=""
fi

# ── Temporary tmux shim to catch accidental launches ───────────────
# Create a small bin dir early in PATH with a harmless `tmux` shim that
# logs invocations to /tmp/devops-tmux-invocations.log and exits. This
# prevents user startup hooks from launching real tmux sessions during
# package installs. The shim is removed when the script exits.
TMP_SHIM_DIR=$(mktemp -d -p /tmp devops-bin.XXXX)
cat > "$TMP_SHIM_DIR/tmux" <<'TMUXSHIM'
#!/usr/bin/env bash
# Intercept tmux calls during the installer; remain silent and exit success.
# This avoids creating log files during each run.
exit 0
TMUXSHIM
chmod +x "$TMP_SHIM_DIR/tmux"
export PATH="$TMP_SHIM_DIR:$PATH"
info "Temporary tmux shim installed (will be removed at script exit)"

cleanup_tmux_shim() {
    rm -rf "${TMP_SHIM_DIR:-}" 2>/dev/null || true
}
trap 'restore_on_exit; cleanup_tmux_shim' EXIT


# ── Banner ───────────────────────────────────────────────────────
clear
echo -e "${NEON}"
cat << 'EOF'
  ╔══════════════════════════════════════════════════════════╗
  ║                                                          ║
  ║    ██████╗ ███████╗██╗   ██╗ ██████╗ ██████╗ ███████╗    ║
  ║    ██╔══██╗██╔════╝██║   ██║██╔═══██╗██╔══██╗██╔════╝    ║
  ║    ██║  ██║█████╗  ██║   ██║██║   ██║██████╔╝███████╗    ║
  ║    ██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██╔═══╝ ╚════██║    ║
  ║    ██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██║     ███████║    ║
  ║    ╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═╝     ╚══════╝    ║
  ║                                                          ║
  ║           DevOps Toolbox Installer v1.0                  ║
  ║           Ubuntu 24.04 LTS  •  x86_64                    ║
  ╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${R}"

echo -e "${GREY}  This script will install:${R}"
echo -e "${GREY}  Terminal  → vim, nvim, fzf, eza, bat, btop, zoxide, tmux, ripgrep, fd, delta, ncdu, tldr, autojump, entr, thefuck, tig${R}"
echo -e "${GREY}  Dev       → git extras, jq, yq, httpie, make, lazygit, gh, direnv, asdf, pyenv, rbenv${R}"
echo -e "${GREY}  DevOps    → docker, podman, lazydocker, kubectl, helm, k9s, kubectx/kubens, krew, kind, terraform, ansible${R}"
echo -e "${GREY}  GUI/Extras→ VSCode, Google Chrome/Chromium, Postman, VLC, keepassxc, wps-office (optional)${R}"
echo -e "${GREY}  Cloud     → aws-cli, gcloud (optional)${R}"
echo ""
read -rp "$(echo -e "${PINK}  Continue? [Y/n]:${R} ")" confirm
[[ "${confirm,,}" =~ ^(n|no)$ ]] && echo "Aborted." && exit 0
echo ""

# Note: .bashrc will be installed at the end of the script to avoid
# triggering interactive config during package installation.



# ── 1. APT BOOTSTRAP ─────────────────────────────────────────────
section "APT Bootstrap"
info "Updating package lists..."
$SUDO apt-get update -qq
success "Package lists updated"

info "Installing prerequisites..."
$SUDO apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    git \
    build-essential \
    2>/dev/null
success "Prerequisites ready"

# ── 2. TERMINAL TOOLS ────────────────────────────────────────────
section "Terminal Tools"

# vim
if check_tool "vim"; then :
else
    info "Installing vim..."
    try "vim" $SUDO apt-get install -y $APT_QUIET vim
fi

# fzf
if check_tool "fzf"; then :
else
    info "Installing fzf..."
    try "fzf" $SUDO apt-get install -y $APT_QUIET fzf
fi

# eza (modern ls)
if check_tool "eza"; then :
else
    info "Installing eza..."
    try "eza" $SUDO apt-get install -y $APT_QUIET eza
fi

# bat (modern cat) — ubuntu names it batcat
if check_tool "bat" "bat" "batcat"; then :
else
    info "Installing bat..."
    if $SUDO apt-get install -y $APT_QUIET bat; then
        success "bat installed"
        mark_installed "bat"
    else
        error "bat install FAILED"
        mark_failed "bat"
    fi
fi
# Always ensure the 'bat' symlink exists when only batcat is present
if has batcat && ! has bat; then
    $SUDO ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
    success "bat symlink created → /usr/bin/batcat"
fi

# btop (modern top)
if check_tool "btop"; then :
else
    info "Installing btop..."
    try "btop" $SUDO apt-get install -y $APT_QUIET btop
fi

# zoxide (smart cd)
if check_tool "zoxide"; then :
else
    info "Installing zoxide..."
    try "zoxide" $SUDO apt-get install -y $APT_QUIET zoxide
fi

# tmux
if check_tool "tmux"; then :
else
    info "Installing tmux..."
    try "tmux" $SUDO apt-get install -y $APT_QUIET tmux
fi

# ripgrep (fast grep)
if check_tool "ripgrep" "rg"; then :
else
    info "Installing ripgrep..."
    try "ripgrep" $SUDO apt-get install -y $APT_QUIET ripgrep
fi

# fd-find (fast find, alias: fd)
if check_tool "fd-find" "fd" "fdfind"; then :
else
    info "Installing fd-find..."
    if $SUDO apt-get install -y $APT_QUIET fd-find; then
        $SUDO ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
        success "fd-find installed  (fd → /usr/bin/fdfind)"
        mark_installed "fd-find"
    else
        warn "fd-find install failed"
        mark_failed "fd-find"
    fi
    success "fd-find installed  (fd → /usr/bin/fdfind)"
    mark_installed "fd-find"
fi

# delta (better git diff)
if check_tool "delta"; then :
else
    info "Installing delta (better git diff)..."
    try "delta" $SUDO apt-get install -y $APT_QUIET git-delta
fi

# ncdu (disk usage explorer)
if check_tool "ncdu"; then :
else
    info "Installing ncdu..."
    try "ncdu" $SUDO apt-get install -y $APT_QUIET ncdu
fi

# tldr (concise CLI examples)
if check_tool "tldr"; then :
else
    info "Installing tldr..."
    try "tldr" $SUDO apt-get install -y $APT_QUIET tldr
fi

# neofetch (welcome banner)
# neofetch (welcome banner)
if check_tool "neofetch"; then :
else
    info "Installing neofetch..."
    try "neofetch" $SUDO apt-get install -y $APT_QUIET neofetch
fi


# ── 3. DEV TOOLS ─────────────────────────────────────────────────
section "Development Tools"

# jq (JSON processor)
if check_tool "jq"; then :
else
    info "Installing jq..."
    try "jq" $SUDO apt-get install -y $APT_QUIET jq
fi

# yq (YAML processor) — prefer mikefarah's v4 binary (modern features)
if command -v yq &>/dev/null; then
    # If current yq is mikefarah's v4, skip. Otherwise attempt to install modern yq.
    if yq --version 2>/dev/null | grep -qi 'mikefarah'; then
        echo -e "${GREY}  ↷  ${BOLD}yq${R}${GREY} already installed (mikefarah) — skipping${R}"
        mark_skipped "yq"
    else
        warn "Detected non-mikefarah 'yq' — installing mikefarah yq v4 to /usr/local/bin"
        if $SUDO curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && $SUDO chmod +x /usr/local/bin/yq; then
            success "yq (mikefarah) installed to /usr/local/bin"
            mark_installed "yq-mikefarah"
        else
            warn "Failed to download mikefarah yq — falling back to distro package"
            try "yq" $SUDO apt-get install -y $APT_QUIET yq
        fi
    fi
else
    info "Installing mikefarah yq (preferred) to /usr/local/bin..."
    if curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /tmp/yq_tmp && chmod +x /tmp/yq_tmp && $SUDO mv /tmp/yq_tmp /usr/local/bin/yq && $SUDO chmod +x /usr/local/bin/yq; then
        success "yq (mikefarah) installed to /usr/local/bin"
        mark_installed "yq-mikefarah"
    else
        warn "Failed to fetch mikefarah yq — trying distro package via apt"
        try "yq" $SUDO apt-get install -y $APT_QUIET yq
    fi
fi

# httpie (friendly HTTP client)
if check_tool "httpie" "http" "httpie"; then :
else
    info "Installing httpie..."
    try "httpie" $SUDO apt-get install -y $APT_QUIET httpie
fi

# make
if check_tool "make"; then :
else
    info "Installing make..."
    try "make" $SUDO apt-get install -y $APT_QUIET make
fi

# Python extras
info "Installing Python extras (pip, venv, dev headers)..."
if run "$SUDO apt-get install -y $APT_QUIET python3-pip python3-venv python3-dev python3-distutils"; then
    success "Python3 extras ready"
    mark_installed "python3-venv"
else
    warn "Python3 extras install failed — attempting fallbacks for distutils"

    # Try versioned distutils package (e.g. python3.12-distutils)
    if command -v python3 &>/dev/null; then
        pyver=$(python3 -c 'import sys; print("{}.{}".format(sys.version_info[0], sys.version_info[1]))' 2>/dev/null || true)
        if [[ -n "$pyver" ]]; then
            alt_pkg="python${pyver}-distutils"
            info "Trying alternative package: ${alt_pkg}"
            if run "$SUDO apt-get install -y $APT_QUIET python3-pip python3-venv python3-dev ${alt_pkg}"; then
                success "Python3 extras ready (installed ${alt_pkg})"
                mark_installed "python3-venv"
                alt_retry=1
            fi
        fi
    fi

    # If still failing, try enabling 'universe' and retry distutils
    if [[ "${alt_retry:-0}" -ne 1 ]]; then
        warn "Attempting to enable 'universe' repository and retry distutils install"
        # Ensure add-apt-repository is available
        run "$SUDO apt-get install -y $APT_QUIET software-properties-common || true"
        if run "$SUDO add-apt-repository -y universe"; then
            run "$SUDO apt-get update $APT_QUIET"
            if run "$SUDO apt-get install -y $APT_QUIET python3-distutils"; then
                success "Python3 distutils installed from universe"
                # Ensure other extras are present
                run "$SUDO apt-get install -y $APT_QUIET python3-pip python3-venv python3-dev || true"
                mark_installed "python3-venv"
                alt_retry=1
            fi
        fi
    fi

    if [[ "${alt_retry:-0}" -ne 1 ]]; then
        info "Attempting install without python3-distutils (install pip/venv/dev headers only)"
        if run "$SUDO apt-get install -y $APT_QUIET python3-pip python3-venv python3-dev"; then
            success "Python3 extras installed (without python3-distutils)"
            mark_installed "python3-venv"

            # Ensure pip is usable: try ensurepip, else get-pip.py
            if ! command -v pip3 &>/dev/null; then
                info "pip not found — trying python3 -m ensurepip --upgrade"
                if run "python3 -m ensurepip --upgrade"; then
                    info "ensurepip succeeded"
                else
                    info "ensurepip failed — downloading get-pip.py"
                    if run "curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py"; then
                        run "sudo python3 /tmp/get-pip.py" || run "python3 /tmp/get-pip.py"
                    fi
                fi
            fi

            # Upgrade pip/setuptools/wheel only if we're inside a virtualenv; otherwise skip and ensure pipx
            in_venv=0
            if command -v python3 &>/dev/null; then
                in_venv=$(python3 - <<'PY'
import sys, os
print(1 if getattr(sys, 'base_prefix', None) != getattr(sys, 'prefix', None) or 'VIRTUAL_ENV' in os.environ else 0)
PY
)
            fi
            if [[ "$in_venv" -eq 1 ]]; then
                if [[ "${DEBUG:-0}" -eq 1 ]]; then
                    python3 -m pip install --upgrade pip setuptools wheel || true
                else
                    python3 -m pip install --upgrade pip setuptools wheel 2>/dev/null || true
                fi
            else
                warn "Not in a virtualenv; skipping system pip upgrades (PEP 668 environments)"
                # Ensure pipx is available for user-level installs
                if ! command -v pipx &>/dev/null; then
                    info "Installing pipx for user-level Python apps"
                    run "$SUDO apt-get install -y $APT_QUIET pipx || true"
                fi
            fi
        else
            warn "Python3 extras install FAILED — continuing with remaining steps"
            mark_failed "python3-venv"
        fi
    fi
fi

# Node version manager (nvm) — installs to ~/.nvm
if [[ -d "$HOME/.nvm" ]]; then
    NVM_VERSION_INSTALLED=$(cat "$HOME/.nvm/package.json" 2>/dev/null | grep '"version"' | cut -d'"' -f4 || echo "unknown")
    echo -e "${GREY}  ↷  ${BOLD}nvm${R}${GREY} already installed — skipping${R}"
    echo -e "${GREY}       cmd : ${HOME}/.nvm/nvm.sh${R}"
    echo -e "${GREY}       ver : ${NVM_VERSION_INSTALLED}${R}"
    mark_skipped "nvm"
else
    info "Installing nvm (Node Version Manager)..."
    NVM_VERSION="v0.39.7"
    if run "curl -fsSL \"https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh\" | bash --noprofile --norc"; then
        success "nvm ${NVM_VERSION} installed  (~/.nvm)"
        mark_installed "nvm"
        echo -e "${GREY}       run : source ~/.bashrc && nvm install --lts${R}"
    else
        warn "nvm install failed (raw.githubusercontent.com may be blocked)"
        mark_failed "nvm"
    fi
fi

# GitHub CLI (gh)
if check_tool "gh" "gh"; then :
else
    read -rp "$(echo -e "${PINK}  Install GitHub CLI (gh)? [y/N]:${R} ")" do_gh
    if [[ "${do_gh,,}" == "y" ]]; then
        info "Installing GitHub CLI..."
        if $SUDO apt-get install -y $APT_QUIET gh; then
            success "gh installed"
            mark_installed "gh"
        else
            # fallback: GitHub release
            GH_VER=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep tag_name | cut -d'"' -f4) || GH_VER="v2.50.0"
            GH_URL="https://github.com/cli/cli/releases/download/${GH_VER}/gh_${GH_VER#v}_linux_amd64.tar.gz"
            if curl -fsSL "$GH_URL" -o /tmp/gh.tar.gz 2>/dev/null; then
                tar -xzf /tmp/gh.tar.gz -C /tmp/ gh_${GH_VER#v}_linux_amd64/bin/gh 2>/dev/null || true
                $SUDO mv /tmp/gh_${GH_VER#v}_linux_amd64/bin/gh /usr/local/bin/gh 2>/dev/null || true
                $SUDO chmod +x /usr/local/bin/gh || true
                success "gh installed"
                mark_installed "gh"
                rm -f /tmp/gh.tar.gz
            else
                warn "Failed to install gh"
                mark_failed "gh"
            fi
        fi
    fi
fi

# (No Postman shutdown logic — avoid interacting with GUI processes.)

# direnv (per-project env hooks)
if check_tool "direnv" "direnv"; then :
else
    read -rp "$(echo -e "${PINK}  Install direnv (project environment loader)? [y/N]:${R} ")" do_direnv
    if [[ "${do_direnv,,}" == "y" ]]; then
        info "Installing direnv..."
        try "direnv" $SUDO apt-get install -y -qq direnv
    fi
fi

# asdf (version manager)
if [[ -d "$HOME/.asdf" ]]; then
    echo -e "${GREY}  ↷  asdf — already installed${R}"
    mark_skipped "asdf"
else
    read -rp "$(echo -e "${PINK}  Install asdf (universal version manager)? [y/N]:${R} ")" do_asdf
    if [[ "${do_asdf,,}" == "y" ]]; then
        info "Installing asdf..."
        if run "git clone --depth 1 https://github.com/asdf-vm/asdf.git \"$HOME/.asdf\""; then
            success "asdf installed to $HOME/.asdf"
            mark_installed "asdf"
            echo -e "${GREY}  → Add to ~/.bashrc: source \$HOME/.asdf/asdf.sh${R}"
        else
            warn "Failed to clone asdf repository"
            mark_failed "asdf"
        fi
    fi
fi

# Termius (optional SSH client)
if check_tool "termius" "termius"; then :
else
    read -rp "$(echo -e "${PINK}  Install Termius SSH client? [y/N]:${R} ")" do_termius
    if [[ "${do_termius,,}" == "y" ]]; then
        info "Installing Termius..."
        if command -v snap &>/dev/null; then
            if run "$SUDO snap install termius-app --classic"; then
                success "Termius installed"
                mark_installed "termius"
            else
                warn "Termius snap install failed"
                mark_failed "termius"
            fi
        else
            warn "snap not available — cannot install Termius automatically"
            echo -e "${YELLOW}  ⚠${R}  Please install Termius manually from: https://www.termius.com/download"
            mark_failed "termius"
        fi
    fi
fi


# ── 4. DOCKER ────────────────────────────────────────────────────
section "Docker"

if check_tool "docker"; then :
else
    info "Adding Docker GPG key and repo..."
    $SUDO install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
    $SUDO apt-get update $APT_QUIET
    info "Installing Docker Engine + Compose..."
    if $SUDO apt-get install -y $APT_QUIET \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin; then
        success "Docker installed"
        mark_installed "docker"
        if [[ $EUID -ne 0 ]]; then
            $SUDO usermod -aG docker "$USER" 2>/dev/null || true
            warn "Added $USER to 'docker' group — log out & back in to use docker without sudo"
        fi
        run "$SUDO systemctl enable --now docker" || true
    else
        error "Docker install failed"
        mark_failed "docker"
    fi
fi

# lazydocker (TUI for docker)
if check_tool "lazydocker"; then :
else
    info "Installing lazydocker..."
    LAZYDOCKER_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest \
        2>/dev/null | grep tag_name | cut -d'"' -f4 | tr -d 'v') || LAZYDOCKER_VERSION="0.23.3"
    LAZYDOCKER_URL="https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
    if curl -fsSL "$LAZYDOCKER_URL" -o /tmp/lazydocker.tar.gz 2>/dev/null; then
        tar -xzf /tmp/lazydocker.tar.gz -C /tmp/ lazydocker 2>/dev/null
        $SUDO mv /tmp/lazydocker /usr/local/bin/lazydocker
        $SUDO chmod +x /usr/local/bin/lazydocker
        success "lazydocker ${LAZYDOCKER_VERSION} installed"
        mark_installed "lazydocker"
    else
        warn "lazydocker download failed (GitHub may be blocked)"
        mark_failed "lazydocker"
    fi
fi

# Podman (daemonless containers)
if check_tool "podman" "podman"; then :
    echo -e "${GREY}  ↷  podman — already installed${R}"
    mark_skipped "podman"
else
    read -rp "$(echo -e "${PINK}  Install Podman (optional)? [y/N]:${R} ")" do_podman
    if [[ "${do_podman,,}" == "y" ]]; then
        info "Installing podman..."
        if $SUDO apt-get install -y $APT_QUIET podman; then
            success "podman installed"
            mark_installed "podman"
        else
            warn "Podman install failed via apt"
            mark_failed "podman"
        fi
    fi
fi


# ── 5. KUBERNETES ─────────────────────────────────────────────────
section "Kubernetes Tools"

# kubectl
if check_tool "kubectl"; then :
else
    info "Installing kubectl..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
        | $SUDO gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
        | $SUDO tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
    $SUDO apt-get update $APT_QUIET
    if $SUDO apt-get install -y $APT_QUIET kubectl; then
        success "kubectl installed"
        mark_installed "kubectl"
    else
        error "kubectl install failed"
        mark_failed "kubectl"
    fi
fi

# helm
if check_tool "helm"; then :
else
    info "Installing helm..."
    if run "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash --noprofile --norc"; then
        success "helm installed"
        mark_installed "helm"
    else
        error "helm install failed"
        mark_failed "helm"
    fi
fi

# k9s (TUI for kubernetes)
if check_tool "k9s"; then :
else
    info "Installing k9s (Kubernetes TUI)..."
    K9S_VERSION=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest \
        2>/dev/null | grep tag_name | cut -d'"' -f4) || K9S_VERSION="v0.32.4"
    K9S_URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
    if curl -fsSL "$K9S_URL" -o /tmp/k9s.tar.gz 2>/dev/null; then
        tar -xzf /tmp/k9s.tar.gz -C /tmp/ k9s 2>/dev/null
        $SUDO mv /tmp/k9s /usr/local/bin/k9s
        success "k9s ${K9S_VERSION} installed"
        mark_installed "k9s"
    else
        warn "k9s download failed (GitHub may be blocked)"
        mark_failed "k9s"
    fi
fi

# kind (Kubernetes IN Docker) — useful for local clusters
if check_tool "kind" "kind"; then :
    echo -e "${GREY}  ↷  kind — already installed${R}"
    mark_skipped "kind"
else
    read -rp "$(echo -e "${PINK}  Install kind (local k8s)? [y/N]:${R} ")" do_kind
    if [[ "${do_kind,,}" == "y" ]]; then
        info "Installing kind..."
        KIND_VER=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/kind/releases/latest 2>/dev/null | grep tag_name | cut -d'"' -f4) || KIND_VER="v0.20.0"
        KIND_URL="https://kind.sigs.k8s.io/dl/${KIND_VER}/kind-linux-amd64"
        if curl -fsSL "$KIND_URL" -o /tmp/kind && $SUDO mv /tmp/kind /usr/local/bin/kind && $SUDO chmod +x /usr/local/bin/kind; then
            success "kind installed"
            mark_installed "kind"
        else
            warn "Failed to install kind"
            mark_failed "kind"
        fi
    fi
fi

# kubectx + kubens
if check_tool "kubectx/kubens" "kubectx"; then :
else
    info "Installing kubectx & kubens..."
    if $SUDO apt-get install -y $APT_QUIET kubectx; then
        success "kubectx + kubens installed"
        mark_installed "kubectx/kubens"
    else
        warn "kubectx not in apt — trying manual install..."
        KUBECTX_VER="0.9.5"
        BASE="https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VER}"
        if run "curl -fsSL \"${BASE}/kubectx_v${KUBECTX_VER}_linux_x86_64.tar.gz\" | $SUDO tar -xz -C /usr/local/bin/ kubectx" && \
           run "curl -fsSL \"${BASE}/kubens_v${KUBECTX_VER}_linux_x86_64.tar.gz\" | $SUDO tar -xz -C /usr/local/bin/ kubens"; then
            success "kubectx + kubens ${KUBECTX_VER} installed"
            mark_installed "kubectx/kubens"
        else
            warn "kubectx install failed"
            mark_failed "kubectx/kubens"
        fi
    fi
fi

# krew (kubectl plugin manager) + plugins
if command -v kubectl &>/dev/null; then
    KREW_INSTALLED=0
    if command -v kubectl-krew &>/dev/null || [[ -x "$HOME/.krew/bin/kubectl-krew" ]]; then
        KREW_INSTALLED=1
    fi

    if [[ ${KREW_INSTALLED} -eq 1 ]]; then
        echo -e "${GREY}  ↷  krew — already installed${R}"
        mark_skipped "krew"
    else
        read -rp "$(echo -e "${PINK}  Install kubectl krew (plugin manager)? [y/N]:${R} ")" do_krew
        if [[ "${do_krew,,}" == "y" ]]; then
            info "Installing krew (kubectl plugin manager)..."
            run "(set -x; cd \"$(mktemp -d)\" && OS=\"$(uname | tr '[:upper:]' '[:lower:]')\" && ARCH=\"$(uname -m)\" && ARCH=\"${ARCH/x86_64/amd64}\" && KREW=\"krew-${OS}_${ARCH}.tar.gz\" && curl -fsSL \"https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}\" -o \"${KREW}\" && tar zxvf \"${KREW}\" && ./*-*/install.sh) || true"
            # Ensure krew bin is on PATH for this script
            export PATH="${HOME}/.krew/bin:$PATH"
            if command -v kubectl-krew &>/dev/null || (command -v kubectl &>/dev/null && run "kubectl krew >/dev/null"); then
                success "krew installed"
                mark_installed "krew"
                # Install kc plugin if available
                if run "kubectl krew search kc >/dev/null"; then
                    if run "kubectl krew install kc >/dev/null"; then
                        success "krew plugin 'kc' installed"
                        mark_installed "krew-plugin-kc"
                    else
                        warn "Failed to install krew plugin 'kc'"
                        mark_failed "krew-plugin-kc"
                    fi
                else
                    warn "krew plugin 'kc' not found in index"
                fi

                # Offer additional recommended plugins
                if [[ -t 0 ]]; then
                    echo ""
                    echo -e "${CYAN}Recommended krew plugins:${R} ctx, ns, konfig, view-secret, who-can"
                    read -rp "$(echo -e "${PINK}  Install recommended krew plugins now? [y/N]:${R} ")" do_krew_plugins
                    if [[ "${do_krew_plugins,,}" == "y" ]]; then
                        PLUGINS=(ctx ns konfig view-secret who-can)
                        for p in "${PLUGINS[@]}"; do
                            if run "kubectl krew search \"$p\" >/dev/null"; then
                                if run "kubectl krew install \"$p\" >/dev/null"; then
                                    success "krew plugin '${p}' installed"
                                    mark_installed "krew-plugin-${p}"
                                else
                                    warn "Failed to install krew plugin '${p}'"
                                    mark_failed "krew-plugin-${p}"
                                fi
                            else
                                warn "krew plugin '${p}' not found"
                            fi
                        done
                    fi
                fi
            else
                warn "krew installation failed or kubectl not available in PATH"
                mark_failed "krew"
            fi
        fi
    fi
fi


# ── 6. INFRASTRUCTURE AS CODE ────────────────────────────────────
section "Infrastructure as Code"

# terraform
if check_tool "terraform"; then :
else
    info "Installing terraform..."
    wget -qO /tmp/hashicorp.gpg https://apt.releases.hashicorp.com/gpg 2>/dev/null
    $SUDO gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        /tmp/hashicorp.gpg 2>/dev/null
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | $SUDO tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
    $SUDO apt-get update $APT_QUIET
    if $SUDO apt-get install -y $APT_QUIET terraform; then
        success "terraform installed"
        mark_installed "terraform"
    else
        error "terraform install failed"
        mark_failed "terraform"
    fi
fi

# ansible
if check_tool "ansible"; then :
else
    info "Installing ansible..."
    $SUDO apt-get install -y $APT_QUIET software-properties-common
    if $SUDO apt-get install -y $APT_QUIET ansible; then
        success "ansible installed"
        mark_installed "ansible"
    else
        error "ansible install failed"
        mark_failed "ansible"
    fi
fi


# ── 7. CLOUD CLIs ────────────────────────────────────────────────
section "Cloud CLIs  (optional — press Enter to skip)"

# AWS CLI
echo ""
if check_tool "aws-cli" "aws"; then
    echo -e "${GREY}  ↷  AWS CLI — already installed${R}"
    mark_skipped "aws-cli"
else
    read -rp "$(echo -e "${PINK}  Install AWS CLI? [y/N]:${R} ")" install_aws
    if [[ "${install_aws,,}" == "y" ]]; then
        info "Installing AWS CLI v2..."
        curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
            -o /tmp/awscliv2.zip 2>/dev/null
        unzip -q /tmp/awscliv2.zip -d /tmp/
        if run "$SUDO /tmp/aws/install"; then
            success "AWS CLI v2 installed"
            mark_installed "aws-cli"
        else
            error "AWS CLI install failed"
            mark_failed "aws-cli"
        fi
        rm -rf /tmp/aws /tmp/awscliv2.zip
    else
        echo -e "${GREY}  ↷  AWS CLI — skipped by user${R}"
    fi
fi

# lazygit
if check_tool "lazygit"; then :
else
    info "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
        2>/dev/null | grep tag_name | cut -d'"' -f4 | tr -d 'v') || LAZYGIT_VERSION="0.42.0"
    LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    if curl -fsSL "$LAZYGIT_URL" -o /tmp/lazygit.tar.gz 2>/dev/null; then
        tar -xzf /tmp/lazygit.tar.gz -C /tmp/ lazygit 2>/dev/null
        $SUDO mv /tmp/lazygit /usr/local/bin/lazygit
        success "lazygit ${LAZYGIT_VERSION} installed"
        mark_installed "lazygit"
    else
        warn "lazygit download failed (GitHub may be blocked)"
        mark_failed "lazygit"
    fi
fi


# ── 8. STARSHIP PROMPT (optional upgrade) ────────────────────────
section "Starship Prompt  (optional — supercharges your PS1)"

echo ""
if check_tool "starship"; then
    echo -e "${GREY}  ↷  starship — already installed${R}"
    mark_skipped "starship"
else
    read -rp "$(echo -e "${PINK}  Install Starship prompt? [y/N]:${R} ")" install_starship
    if [[ "${install_starship,,}" == "y" ]]; then
        info "Installing starship..."
        if run "curl -fsSL https://starship.rs/install.sh | sh -s -- --yes"; then
            success "starship installed"
            mark_installed "starship"
            echo ""
            echo -e "${YELLOW}  ⚠  To use starship instead of the custom prompt,${R}"
            echo -e "${YELLOW}     replace the __build_ps1 / PROMPT_COMMAND block in${R}"
            echo -e "${YELLOW}     ~/.bashrc with:${R}"
            echo -e "${CYAN}     eval \"\$(starship init bash)\"${R}"
        else
            warn "Starship install failed (starship.rs may be blocked)"
            mark_failed "starship"
        fi
    else
        echo -e "${GREY}  ↷  starship — skipped by user${R}"
    fi
fi


# ── 8b. NERD FONTS (optional) ───────────────────────────────────
echo ""
# If a Nerd font is already present, skip asking to install
FONT_INSTALLED=0
if command -v fc-list &>/dev/null; then
    if fc-list | grep -i 'nerd' &>/dev/null || fc-list | grep -i 'jetbrains' &>/dev/null; then
        FONT_INSTALLED=1
    fi
else
    if [[ -d "$HOME/.local/share/fonts" ]] && ls "$HOME/.local/share/fonts" | grep -i 'nerd' &>/dev/null; then
        FONT_INSTALLED=1
    fi
fi

if [[ "$FONT_INSTALLED" -eq 1 ]]; then
    echo -e "${GREY}  ↷  Nerd Font — already installed${R}"
    mark_skipped "nerd-font"
else
    read -rp "$(echo -e "${PINK}  Install JetBrainsMono Nerd Font? [y/N]:${R} ")" install_fonts
    if [[ "${install_fonts,,}" == "y" ]]; then
        info "Installing JetBrainsMono Nerd Font to ~/.local/share/fonts..."
        mkdir -p "$HOME/.local/share/fonts"
        TEMP_ZIP="/tmp/JetBrainsMonoNerd.zip"
        if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip" -o "$TEMP_ZIP"; then
            if run "unzip -o \"$TEMP_ZIP\" -d \"$HOME/.local/share/fonts\""; then
                run "fc-cache -fv \"$HOME/.local/share/fonts\" || true"
                success "JetBrainsMono Nerd Font installed to $HOME/.local/share/fonts"
                mark_installed "JetBrainsMono Nerd Font"
            else
                warn "Failed to unzip Nerd Font archive"
                mark_failed "JetBrainsMono Nerd Font"
            fi
            rm -f "$TEMP_ZIP"
        else
            warn "Failed to download Nerd Font (network or GitHub blocked)"
            mark_failed "JetBrainsMono Nerd Font"
        fi
    else
        echo -e "${GREY}  ↷  Nerd Font — skipped by user${R}"
    fi
fi

# Check whether Nerd Font installed so we can tell user about icons
if command -v fc-list &>/dev/null; then
    if fc-list | grep -i 'nerd' &>/dev/null || fc-list | grep -i 'jetbrains' &>/dev/null; then
        if command -v eza &>/dev/null; then
            success "Nerd font detected — eza icons should display correctly"
        else
            success "Nerd font detected"
        fi
        mark_installed "nerd-font-detected"
    else
        warn "No Nerd font detected — icons may not display in your terminal"
        echo -e "  → To enable icons, re-run this installer and choose to install the Nerd Font,\n    or install a Nerd/Patched font manually (see README.md for instructions)."
        # If we have a TTY, offer to install now
        if [[ -t 0 ]]; then
            read -rp "Install JetBrainsMono Nerd Font now? [y/N]: " resp
            if [[ "${resp,,}" == "y" ]]; then
                info "Installing JetBrainsMono Nerd Font to ~/.local/share/fonts..."
                mkdir -p "$HOME/.local/share/fonts"
                TEMP_ZIP="/tmp/JetBrainsMonoNerd.zip"
                if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip" -o "$TEMP_ZIP"; then
                    if run "unzip -o \"$TEMP_ZIP\" -d \"$HOME/.local/share/fonts\""; then
                        run "fc-cache -fv \"$HOME/.local/share/fonts\" || true"
                        success "JetBrainsMono Nerd Font installed to $HOME/.local/share/fonts"
                        mark_installed "JetBrainsMono Nerd Font"
                        # show icon test
                        echo -e "\nIcon test: ⚡        🐚\n"
                    else
                        warn "Failed to unzip Nerd Font archive"
                        mark_failed "JetBrainsMono Nerd Font"
                    fi
                    rm -f "$TEMP_ZIP"
                else
                    warn "Failed to download Nerd Font (network or GitHub blocked)"
                    mark_failed "JetBrainsMono Nerd Font"
                fi
            fi
        fi
    fi
else
    # fc-list not available; check local fonts folder as fallback
    if [[ -d "$HOME/.local/share/fonts" ]] && ls "$HOME/.local/share/fonts" | grep -i 'nerd' &>/dev/null; then
        success "Nerd font files found in ~/.local/share/fonts — icons should display if your terminal uses that font"
        mark_installed "nerd-font-detected"
    else
        warn "Could not detect fontconfig (fc-list) — cannot auto-detect Nerd fonts"
        echo -e "  → If icons don't show, install a Nerd Font and set it as your terminal font (see README.md)."
        if [[ -t 0 ]]; then
            read -rp "Attempt to install JetBrainsMono Nerd Font now? [y/N]: " resp2
            if [[ "${resp2,,}" == "y" ]]; then
                mkdir -p "$HOME/.local/share/fonts"
                TEMP_ZIP="/tmp/JetBrainsMonoNerd.zip"
                if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip" -o "$TEMP_ZIP"; then
                    if run "unzip -o \"$TEMP_ZIP\" -d \"$HOME/.local/share/fonts\""; then
                        run "fc-cache -fv \"$HOME/.local/share/fonts\" || true"
                        success "JetBrainsMono Nerd Font installed to $HOME/.local/share/fonts"
                        mark_installed "JetBrainsMono Nerd Font"
                        echo -e "\nIcon test: ⚡        🐚\n"
                    else
                        warn "Failed to unzip Nerd Font archive"
                        mark_failed "JetBrainsMono Nerd Font"
                    fi
                    rm -f "$TEMP_ZIP"
                else
                    warn "Failed to download Nerd Font (network or GitHub blocked)"
                    mark_failed "JetBrainsMono Nerd Font"
                fi
            fi
        fi
    fi
fi


# Deduplicate arrays in-place (preserve order) to avoid duplicate entries
uniq_inplace() {
    local -n arr=$1
    local tmp=()
    local v existing found
    for v in "${arr[@]:-}"; do
        found=0
        for existing in "${tmp[@]:-}"; do
            if [[ "${existing}" == "${v}" ]]; then
                found=1
                break
            fi
        done
        if [[ "$found" -eq 0 ]]; then
            tmp+=("$v")
        fi
    done
    arr=("${tmp[@]}")
}

# Ensure summary lists contain unique entries
uniq_inplace INSTALLED
uniq_inplace SKIPPED
uniq_inplace FAILED

# ── 9. SUMMARY ───────────────────────────────────────────────────
# ── 9. ADDITIONAL TOOLS (suggested) ─────────────────────────────
section "Additional Tools"

# autojump (fast directory jumping)
if check_tool "autojump" "autojump"; then :
else
    info "Installing autojump..."
    try "autojump" $SUDO apt-get install -y -qq autojump
fi

# thefuck (shell command suggestions)
if check_tool "thefuck" "thefuck"; then :
else
    info "Installing thefuck (preferred: pipx) ..."
    # Prefer pipx for isolated, up-to-date Python CLIs. Fall back to apt or pip3 --user.
        if command -v pipx &>/dev/null; then
            try "thefuck" pipx install thefuck
            # Ensure setuptools (which provides distutils backports) is available in the pipx venv
            info "Ensuring setuptools is available inside the thefuck pipx venv..."
            run "pipx inject thefuck setuptools || true"
            # Some versions of Python remove 'imp'; add a small compatibility shim
            for base in "$HOME/.local/share/pipx/venvs" "$HOME/.local/pipx/venvs" "$HOME/.local/pipx/venvs" "$HOME/.local/pipx/venvs" "$HOME/.local/pipx/venvs" "$HOME/.local/pipx/venvs" "$HOME/.local/pipx/venvs" "$HOME/.local/pipx/venvs"; do
                venv_dir="$base/thefuck"
                if [[ -d "$venv_dir" ]]; then
                    if [[ -x "$venv_dir/bin/python" ]]; then
                        site_pkg=$("$venv_dir/bin/python" -c "import site,sys,os; s=site.getsitepackages(); print(s[0] if s else os.path.join(sys.prefix,'lib', 'python'+'.'.join(map(str,sys.version_info[:2])), 'site-packages'))")
                        if [[ -d "$site_pkg" ]]; then
                            shim="$site_pkg/imp.py"
                            if [[ ! -f "$shim" ]]; then
                                cat > "$shim" <<'IMP_SHIM'
"""Minimal shim for Python's deprecated 'imp' module used by older packages.
Provides load_source() using importlib for compatibility.
"""
import importlib.util
import sys
def load_source(name, pathname):
    spec = importlib.util.spec_from_file_location(name, pathname)
    module = importlib.util.module_from_spec(spec)
    loader = spec.loader
    if loader is None:
        raise ImportError("cannot load %s" % name)
    loader.exec_module(module)
    sys.modules[name] = module
    return module
IMP_SHIM
                                success "Added imp shim to thefuck pipx venv"
                            fi
                        fi
                    fi
                fi
            done
        else
        info "pipx not found — attempting to install pipx via apt"
        if run "$SUDO apt-get install -y $APT_QUIET pipx python3-venv"; then
            success "pipx installed"
            if command -v pipx &>/dev/null; then
                try "thefuck" pipx install thefuck
            else
                warn "pipx still not on PATH — will try pip3 --user"
                if run "python3 -m pip install --user thefuck"; then
                    success "thefuck installed via pip3 --user"
                    mark_installed "thefuck"
                    echo -e "${YELLOW}  ⚠  Ensure ~/.local/bin is on your PATH to run 'thefuck'${R}"
                else
                    warn "Failed to install thefuck via pip3 --user"
                    mark_failed "thefuck"
                fi
            fi
        else
            warn "Failed to install pipx via apt — trying pip3 --user"
            if python3 -m pip install --user thefuck &>/dev/null; then
                success "thefuck installed via pip3 --user"
                mark_installed "thefuck"
                echo -e "${YELLOW}  ⚠  Ensure ~/.local/bin is on your PATH to run 'thefuck'${R}"
            else
                warn "Failed to install thefuck via pip3 --user"
                mark_failed "thefuck"
            fi
        fi
    fi
fi
# enable thefuck alias in this shell (if available)
if command -v thefuck &>/dev/null; then
    eval "$(thefuck --alias)"
fi

# entr (run arbitrary commands when files change)
if check_tool "entr" "entr"; then :
else
    info "Installing entr..."
    try "entr" $SUDO apt-get install -y -qq entr
fi

# skim removed — use fzf (already included)

# tig (ncurses git interface)
if check_tool "tig" "tig"; then :
else
    info "Installing tig..."
    try "tig" $SUDO apt-get install -y -qq tig
fi

# git-crypt (transparent file encryption for git)
if check_tool "git-crypt" "git-crypt"; then :
else
    info "Installing git-crypt..."
    try "git-crypt" $SUDO apt-get install -y -qq git-crypt
fi

# rbenv (Ruby version manager) — optional
if check_tool "rbenv" "rbenv"; then :
else
    read -rp "$(echo -e "${PINK}  Install rbenv (Ruby version manager)? [y/N]:${R} ")" do_rbenv
    if [[ "${do_rbenv,,}" == "y" ]]; then
        info "Installing rbenv..."
        try "rbenv" git clone --depth 1 https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
        echo -e "${GREY}  → Add to ~/.bashrc: export PATH=\"\$HOME/.rbenv/bin:\$PATH\"; eval \"\$(rbenv init -)\"${R}"
    fi
fi

# pyenv (Python version manager)
if check_tool "pyenv" "pyenv"; then :
else
    read -rp "$(echo -e "${PINK}  Install pyenv (Python version manager)? [y/N]:${R} ")" do_pyenv
    if [[ "${do_pyenv,,}" == "y" ]]; then
        info "Installing pyenv..."
        if run "git clone --depth 1 https://github.com/pyenv/pyenv.git \"$HOME/.pyenv\""; then
            success "pyenv installed to $HOME/.pyenv"
            mark_installed "pyenv"
            echo -e "${GREY}  → Add to ~/.bashrc: export PYENV_ROOT=\"\$HOME/.pyenv\"; export PATH=\"\$PYENV_ROOT/bin:\\$PATH\"; eval \"\$(pyenv init --path)\"${R}"
        else
            warn "pyenv clone failed"
            mark_failed "pyenv"
        fi
    fi
fi

# neovim (modern vim) — skip if user already has nvim
if check_tool "nvim" "nvim"; then :
else
    info "Installing neovim..."
    try "neovim" $SUDO apt-get install -y -qq neovim
fi

# micro (simple terminal editor)
if check_tool "micro" "micro"; then :
else
    info "Installing micro editor..."
    try "micro" $SUDO apt-get install -y -qq micro
fi

# chromium (browser) — skip if chrome/firefox present
if check_tool "chromium" "chromium-browser" "chromium"; then :
else
    read -rp "$(echo -e "${PINK}  Install Chromium browser? [y/N]:${R} ")" do_chrome
    if [[ "${do_chrome,,}" == "y" ]]; then
        info "Installing chromium..."
        try "chromium" $SUDO apt-get install -y -qq chromium-browser
    fi
fi

# keepassxc (password manager)
if check_tool "keepassxc" "keepassxc"; then :
else
    read -rp "$(echo -e "${PINK}  Install keepassxc (password manager)? [y/N]:${R} ")" do_keepass
    if [[ "${do_keepass,,}" == "y" ]]; then
        info "Installing keepassxc..."
        try "keepassxc" $SUDO apt-get install -y -qq keepassxc
    fi
fi

    # wps-office (optional — lightweight MS Office-compatible suite)
    if check_tool "wps-office" "wps"; then :
    else
        read -rp "$(echo -e "${PINK}  Install WPS Office (optional)? [y/N]:${R} ")" do_wps
        if [[ "${do_wps,,}" == "y" ]]; then
            # If LibreOffice / OpenOffice is present, offer to remove it to avoid conflicts
            if command -v soffice &>/dev/null || dpkg -l 2>/dev/null | grep -Ei 'libreoffice|openoffice' &>/dev/null; then
                echo ""
                read -rp "$(echo -e "${YELLOW}  Detected LibreOffice/OpenOffice. Remove it before installing WPS? [y/N]:${R} ")" remove_office
                if [[ "${remove_office,,}" == "y" ]]; then
                    info "Removing LibreOffice / OpenOffice..."
                    $SUDO apt-get remove --purge -y libreoffice* openoffice* 2>/dev/null || true
                    $SUDO apt-get autoremove -y --purge 2>/dev/null || true
                fi
            fi

            info "Attempting to install WPS Office (via apt if available)..."
            if try "wps-office" $SUDO apt-get install -y -qq wps-office; then :
            else
                warn "WPS not available in apt — skipping automatic download. You can install manually from https://www.wps.com/linux"
                mark_failed "wps-office"
            fi
        fi
    fi

# hadolint, tfsec, kubeval removed — prefer external linters/plugins or add-on installs

# taskwarrior (task management)
if check_tool "task" "task"; then :
else
    info "Installing taskwarrior..."
    try "taskwarrior" $SUDO apt-get install -y -qq taskwarrior
fi

echo ""
echo -e "${NEON}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
echo -e "${BOLD}  INSTALLATION SUMMARY${R}"
echo -e "${NEON}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
echo ""

if [[ ${#INSTALLED[@]} -gt 0 ]]; then
    echo -e "${BGREEN}  Installed (${#INSTALLED[@]}):${R}"
    for item in "${INSTALLED[@]}"; do
        echo -e "${GREEN}    ✔  ${item}${R}"
    done
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo ""
    echo -e "${GREY}  Already present (${#SKIPPED[@]}):${R}"
    for item in "${SKIPPED[@]}"; do
        echo -e "${GREY}    ↷  ${item}${R}"
    done
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}  Failed (${#FAILED[@]}):${R}"
    for item in "${FAILED[@]}"; do
        echo -e "${RED}    ✘  ${item}${R}"
    done
    echo -e "${YELLOW}  → These likely need internet access to GitHub/external repos${R}"
fi

echo ""
echo -e "${BCYAN}  Next steps:${R}"
echo -e "${CYAN}    1. source ~/.bashrc${R}           ${GREY}← activate everything now${R}"
echo -e "${CYAN}    2. Log out & back in${R}           ${GREY}← for docker group to take effect${R}"
if [[ ${#FAILED[@]} -gt 0 ]]; then
echo -e "${CYAN}    3. Re-run for failed tools${R}     ${GREY}← once network access is open${R}"
fi
echo ""
echo -e "${NEON}  Happy hacking! ⚡${R}"
echo ""

# ── OPTIONAL EXTRAS (GUI & misc) ─────────────────────────────────
section "Optional Extras (GUI & misc)"

echo ""
# VSCode
if check_tool "vscode" "code"; then
    echo -e "${GREY}  ↷  VSCode — already installed${R}"
    mark_skipped "vscode"
else
    read -rp "$(echo -e "${PINK}  Install Visual Studio Code (snap)? [y/N]:${R} ")" do_vscode
    if [[ "${do_vscode,,}" == "y" ]]; then
        if command -v snap &>/dev/null; then
            try "vscode" $SUDO snap install --classic code
        else
            info "Installing VSCode via Microsoft APT repo..."
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | $SUDO gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg 2>/dev/null || true
            echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" | $SUDO tee /etc/apt/sources.list.d/vscode.list > /dev/null
            $SUDO apt-get update -qq
            try "vscode" $SUDO apt-get install -y -qq code
        fi
    fi
fi

# Google Chrome
if check_tool "google-chrome" "google-chrome"; then
    echo -e "${GREY}  ↷  Google Chrome — already installed${R}"
    mark_skipped "google-chrome"
else
    read -rp "$(echo -e "${PINK}  Install Google Chrome? [y/N]:${R} ")" do_chrome
    if [[ "${do_chrome,,}" == "y" ]]; then
        TEMP_DEB="/tmp/google-chrome-stable_current_amd64.deb"
        curl -fsSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o "$TEMP_DEB" 2>/dev/null || true
        if [[ -f "$TEMP_DEB" ]]; then
            try "google-chrome" $SUDO apt-get install -y -qq "$TEMP_DEB"
            rm -f "$TEMP_DEB"
        else
            warn "Failed to download Google Chrome package"
            mark_failed "google-chrome"
        fi
    fi
fi

# Lens (Kubernetes IDE)
LENS_FOUND=0
if command -v lens &>/dev/null; then
    LENS_FOUND=1
elif command -v kontena-lens &>/dev/null; then
    LENS_FOUND=1
elif [[ -x "/snap/bin/kontena-lens" || -x "/snap/bin/lens" ]]; then
    LENS_FOUND=1
elif command -v snap &>/dev/null && snap list kontena-lens &>/dev/null; then
    LENS_FOUND=1
fi

if [[ ${LENS_FOUND} -eq 1 ]]; then
    echo -e "${GREY}  ↷  Lens — already installed${R}"
    mark_skipped "lens"
else
    read -rp "$(echo -e "${PINK}  Install Lens (snap)? [y/N]:${R} ")" do_lens
    if [[ "${do_lens,,}" == "y" ]]; then
        if command -v snap &>/dev/null; then
            try "lens" $SUDO snap install kontena-lens --classic
        else
            warn "Snap not available — please install Lens manually from https://k8slens.dev/"
            mark_failed "lens"
        fi
    fi
fi

# Ensure snapd is available (required for some optional installs like Termius/Lens)
if command -v snap &>/dev/null; then
    echo -e "${GREY}  ↷  snapd — already available${R}"
    mark_skipped "snapd"
else
    info "snap not found — installing snapd (required for some optional apps)"
    if run "$SUDO apt-get install -y $APT_QUIET snapd"; then
        # enable and start snapd socket/service where applicable
        run "$SUDO systemctl enable --now snapd.socket || true"
        # install core snap to ensure classic support is present
        run "$SUDO snap install core || true"
        success "snapd installed"
        mark_installed "snapd"
    else
        warn "Failed to install snapd — optional snap-based apps may not be available"
        mark_failed "snapd"
    fi
fi

# Homebrew (Linuxbrew)
BREW_FOUND=0
if command -v brew &>/dev/null; then
    BREW_FOUND=1
elif [[ -x "$HOME/.linuxbrew/bin/brew" || -x "/home/linuxbrew/.linuxbrew/bin/brew" || -x "/home/$USER/.linuxbrew/bin/brew" ]]; then
    BREW_FOUND=1
fi

if [[ ${BREW_FOUND} -eq 1 ]]; then
    echo -e "${GREY}  ↷  Homebrew — already installed${R}"
    mark_skipped "homebrew"
else
    read -rp "$(echo -e "${PINK}  Install Homebrew (Linux)? [y/N]:${R} ")" do_brew
    if [[ "${do_brew,,}" == "y" ]]; then
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &>/dev/null; then
            success "Homebrew installed"
            mark_installed "homebrew"
        else
            warn "Homebrew install failed"
            mark_failed "homebrew"
        fi
    fi
fi

# Antigravity (placeholder)
if check_tool "antigravity" "antigravity"; then
    echo -e "${GREY}  ↷  antigravity — already installed${R}"
    mark_skipped "antigravity"
else
    read -rp "$(echo -e "${PINK}  Show antigravity install instructions? [y/N]:${R} ")" do_anti
    if [[ "${do_anti,,}" == "y" ]]; then
        echo -e "Visit https://example.com/antigravity-install for manual install instructions (placeholder)"
    fi
fi

# k9s (optional)
if check_tool "k9s" "k9s"; then
    echo -e "${GREY}  ↷  k9s — already installed${R}"
    mark_skipped "k9s"
else
    read -rp "$(echo -e "${PINK}  Install k9s? [y/N]:${R} ")" do_k9s
    if [[ "${do_k9s,,}" == "y" ]]; then
        K9S_VERSION=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest 2>/dev/null | grep tag_name | cut -d'"' -f4) || K9S_VERSION="v0.32.4"
        K9S_URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
        if curl -fsSL "$K9S_URL" -o /tmp/k9s.tar.gz 2>/dev/null; then
            tar -xzf /tmp/k9s.tar.gz -C /tmp/ k9s 2>/dev/null
            $SUDO mv /tmp/k9s /usr/local/bin/k9s
            success "k9s ${K9S_VERSION} installed"
            mark_installed "k9s"
            rm -f /tmp/k9s.tar.gz
        else
            warn "k9s download failed (GitHub may be blocked)"
            mark_failed "k9s"
        fi
    fi
fi

# Postman (API GUI)
if check_tool "postman" "postman"; then
    echo -e "${GREY}  ↷  Postman — already installed${R}"
    mark_skipped "postman"
else
    read -rp "$(echo -e "${PINK}  Install Postman (snap or tar)? [y/N]:${R} ")" do_postman
    if [[ "${do_postman,,}" == "y" ]]; then
        if command -v snap &>/dev/null; then
            try "postman" $SUDO snap install postman
        else
            TEMP_TAR="/tmp/postman.tar.gz"
            if curl -fsSL https://dl.pstmn.io/download/latest/linux64 -o "$TEMP_TAR" 2>/dev/null; then
                $SUDO rm -rf /opt/Postman || true
                $SUDO tar -xzf "$TEMP_TAR" -C /tmp/ || true
                if [[ -d "/tmp/Postman" ]]; then
                    $SUDO mv /tmp/Postman /opt/Postman
                    $SUDO ln -sf /opt/Postman/Postman /usr/local/bin/postman
                    success "Postman installed"
                    mark_installed "postman"
                    rm -f "$TEMP_TAR"
                else
                    warn "Postman archive extracted but expected /tmp/Postman missing"
                    mark_failed "postman"
                fi
            else
                warn "Failed to download Postman archive"
                mark_failed "postman"
            fi
        fi
    fi
fi

# VLC (media player)
if check_tool "vlc" "vlc"; then
    echo -e "${GREY}  ↷  VLC — already installed${R}"
    mark_skipped "vlc"
else
    read -rp "$(echo -e "${PINK}  Install VLC media player? [y/N]:${R} ")" do_vlc
    if [[ "${do_vlc,,}" == "y" ]]; then
        if run "$SUDO apt-get install -y $APT_QUIET vlc"; then
            success "VLC installed"
            mark_installed "vlc"
        elif command -v snap &>/dev/null; then
            try "vlc" $SUDO snap install vlc
        else
            warn "Could not install VLC (no apt or snap available)"
            mark_failed "vlc"
        fi
    fi
fi

# ── Install .bashrc (deferred) ───────────────────────────────────
section "Applying .bashrc"

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BASHRC_SRC="${SCRIPT_DIR}/bashrc"

if [[ -f "$BASHRC_SRC" ]]; then
    BACKUP_PATH="${HOME}/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    if [[ -f "$HOME/.bashrc" ]]; then
        cp "$HOME/.bashrc" "$BACKUP_PATH" 2>/dev/null || true
        success "Original ~/.bashrc backed up  →  ${BACKUP_PATH}"
    elif [[ -n "${PREINSTALL_BACKUP:-}" && -f "${PREINSTALL_BACKUP}" ]]; then
        # We moved the original ~/.bashrc out of the way at script start;
        # promote that temporary backup to the final backup path so the
        # user has a single, clearly named backup file.
        mv "${PREINSTALL_BACKUP}" "$BACKUP_PATH" 2>/dev/null || true
        success "Original ~/.bashrc backed up  →  ${BACKUP_PATH}"
        PREINSTALL_BACKUP=""
    else
        warn "No existing ~/.bashrc found — nothing to back up"
    fi
    cp "$BASHRC_SRC" "$HOME/.bashrc"
    success "New ~/.bashrc installed from ${BASHRC_SRC}"
    mark_installed "bashrc"
else
    warn "bashrc not found at ${BASHRC_SRC}"
    warn "Make sure bashrc sits in the same folder as this script"
    warn "Installation complete — but ~/.bashrc was not updated" 
fi

# Offer to source the new ~/.bashrc when there were no failures
if [[ ${#FAILED[@]} -eq 0 && -t 0 ]]; then
    read -rp "$(echo -e "${PINK}  Source ~/.bashrc now? [y/N]:${R} ")" do_source
    if [[ "${do_source,,}" == "y" ]]; then
        if [[ "${IS_SOURCED:-0}" -eq 1 ]]; then
            # Sourced installer: sourcing will affect the current shell
            source "$HOME/.bashrc"
            success "Sourced ~/.bashrc in current shell"
        else
            # Script was executed; sourcing here won't affect the caller.
            echo -e "${YELLOW}Note: this installer was executed, not sourced.${R}"
            echo -e "${YELLOW}To apply changes to your current shell, run:${R} ${CYAN}source ~/.bashrc${R}"
            read -rp "$(echo -e "${PINK}  Start a new interactive shell now so the changes take effect? [y/N]:${R} ")" start_shell
            if [[ "${start_shell,,}" == "y" ]]; then
                exec "$SHELL" -l
            fi
        fi
    fi
fi

# Cleanup: remove backups / installer logs
remove_list=()
for f in "$HOME"/.bashrc.backup.* "$HOME"/.bashrc.preinstall.* "$SCRIPT_DIR"/tmux-client-*.log; do
    [[ -e "$f" ]] || continue
    remove_list+=("$f")
done

if [[ ${#remove_list[@]} -gt 0 ]]; then
    if [[ "$CLEANUP_AUTO" -eq 1 || "$ASSUME_YES" -eq 1 || ! -t 0 ]]; then
        for f in "${remove_list[@]}"; do
            rm -f "$f" 2>/dev/null || true
            success "Removed ${f}"
        done
    elif [[ -t 0 ]]; then
        echo ""
        echo -e "${GREY}Backup / installer log files found:${R}"
        for f in "${remove_list[@]}"; do
            echo -e "  - ${f}"
        done
        read -rp "$(echo -e "${PINK}  Remove these files now? [y/N]:${R} ")" do_rm
        if [[ "${do_rm,,}" == "y" ]]; then
            for f in "${remove_list[@]}"; do
                rm -f "$f" 2>/dev/null || true
                success "Removed ${f}"
            done
        else
            echo -e "${GREY}  → Backups preserved.${R}"
        fi
    fi
fi

