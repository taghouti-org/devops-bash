#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║          DevOps Toolbox Installer — Ubuntu 24.04 x86_64         ║
# ║   Installs everything needed to make your .bashrc fully alive   ║
# ╚══════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────
R='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
BGREEN='\033[1;32m'
CYAN='\033[0;36m'
BCYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREY='\033[38;5;244m'
NEON='\033[38;5;45m'
PINK='\033[38;5;205m'

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
    if "$@" &>/dev/null; then
        success "$label installed"
        mark_installed "$label"
    else
        error "$label FAILED — check manually"
        mark_failed "$label"
    fi
}

# Check if a binary exists
has() { command -v "$1" &>/dev/null; }

# check_tool NAME [BINARY]
#   If the tool is found: print path + version, mark skipped, return 0 (→ skip install)
#   If not found: return 1 (→ proceed with install)
check_tool() {
    local label="$1"
    local bin="${2:-$1}"   # default binary name == label
    local bin_path ver

    bin_path=$(command -v "$bin" 2>/dev/null) || {
        # also try common alt names passed as extra args
        shift 2 2>/dev/null || shift 1
        for alt in "$@"; do
            bin_path=$(command -v "$alt" 2>/dev/null) && bin="$alt" && break
        done
    }

    if [[ -n "$bin_path" ]]; then
        # Try to get a version string; suppress errors gracefully
        ver=$( "$bin" --version 2>/dev/null \
            || "$bin" version 2>/dev/null \
            || "$bin" -v 2>/dev/null \
            || echo "" ) 
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

# ── Banner ────────────────────────────────────────────────────────
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
echo -e "${GREY}  Terminal  → vim, fzf, eza, bat, btop, zoxide, tmux${R}"
echo -e "${GREY}  DevOps    → docker, kubectl, helm, terraform, ansible${R}"
echo -e "${GREY}  Dev       → git extras, jq, yq, httpie, lazygit${R}"
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
    try "vim" $SUDO apt-get install -y -qq vim
fi

# fzf
if check_tool "fzf"; then :
else
    info "Installing fzf..."
    try "fzf" $SUDO apt-get install -y -qq fzf
fi

# eza (modern ls)
if check_tool "eza"; then :
else
    info "Installing eza..."
    try "eza" $SUDO apt-get install -y -qq eza
fi

# bat (modern cat) — ubuntu names it batcat
if check_tool "bat" "bat" "batcat"; then :
else
    info "Installing bat..."
    $SUDO apt-get install -y -qq bat &>/dev/null && {
        success "bat installed"
        mark_installed "bat"
    } || {
        error "bat install FAILED"
        mark_failed "bat"
    }
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
    try "btop" $SUDO apt-get install -y -qq btop
fi

# zoxide (smart cd)
if check_tool "zoxide"; then :
else
    info "Installing zoxide..."
    try "zoxide" $SUDO apt-get install -y -qq zoxide
fi

# tmux
if check_tool "tmux"; then :
else
    info "Installing tmux..."
    try "tmux" $SUDO apt-get install -y -qq tmux
fi

# ripgrep (fast grep)
if check_tool "ripgrep" "rg"; then :
else
    info "Installing ripgrep..."
    try "ripgrep" $SUDO apt-get install -y -qq ripgrep
fi

# fd-find (fast find, alias: fd)
if check_tool "fd-find" "fd" "fdfind"; then :
else
    info "Installing fd-find..."
    $SUDO apt-get install -y -qq fd-find &>/dev/null
    $SUDO ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
    success "fd-find installed  (fd → /usr/bin/fdfind)"
    mark_installed "fd-find"
fi

# delta (better git diff)
if check_tool "delta"; then :
else
    info "Installing delta (better git diff)..."
    try "delta" $SUDO apt-get install -y -qq git-delta
fi

# ncdu (disk usage explorer)
if check_tool "ncdu"; then :
else
    info "Installing ncdu..."
    try "ncdu" $SUDO apt-get install -y -qq ncdu
fi

# neofetch (welcome banner)
if check_tool "neofetch"; then :
else
    info "Installing neofetch..."
    try "neofetch" $SUDO apt-get install -y -qq neofetch
fi


# ── 3. DEV TOOLS ─────────────────────────────────────────────────
section "Development Tools"

# jq (JSON processor)
if check_tool "jq"; then :
else
    info "Installing jq..."
    try "jq" $SUDO apt-get install -y -qq jq
fi

# yq (YAML processor)
if check_tool "yq"; then :
else
    info "Installing yq..."
    try "yq" $SUDO apt-get install -y -qq yq
fi

# httpie (friendly HTTP client)
if check_tool "httpie" "http" "httpie"; then :
else
    info "Installing httpie..."
    try "httpie" $SUDO apt-get install -y -qq httpie
fi

# make
if check_tool "make"; then :
else
    info "Installing make..."
    try "make" $SUDO apt-get install -y -qq make
fi

# Python extras
info "Installing Python extras (pip, venv, dev headers)..."
$SUDO apt-get install -y -qq python3-pip python3-venv python3-dev &>/dev/null
success "Python3 extras ready"
mark_installed "python3-venv"

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
    if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash &>/dev/null; then
        success "nvm ${NVM_VERSION} installed  (~/.nvm)"
        mark_installed "nvm"
        echo -e "${GREY}       run : source ~/.bashrc && nvm install --lts${R}"
    else
        warn "nvm install failed (raw.githubusercontent.com may be blocked)"
        mark_failed "nvm"
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
    $SUDO apt-get update -qq
    info "Installing Docker Engine + Compose..."
    if $SUDO apt-get install -y -qq \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin &>/dev/null; then
        success "Docker installed"
        mark_installed "docker"
        if [[ $EUID -ne 0 ]]; then
            $SUDO usermod -aG docker "$USER" 2>/dev/null || true
            warn "Added $USER to 'docker' group — log out & back in to use docker without sudo"
        fi
        $SUDO systemctl enable --now docker &>/dev/null || true
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
    $SUDO apt-get update -qq
    if $SUDO apt-get install -y -qq kubectl &>/dev/null; then
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
    if curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
        | bash &>/dev/null; then
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

# kubectx + kubens
if check_tool "kubectx/kubens" "kubectx"; then :
else
    info "Installing kubectx & kubens..."
    if $SUDO apt-get install -y -qq kubectx &>/dev/null; then
        success "kubectx + kubens installed"
        mark_installed "kubectx/kubens"
    else
        warn "kubectx not in apt — trying manual install..."
        KUBECTX_VER="0.9.5"
        BASE="https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VER}"
        if curl -fsSL "${BASE}/kubectx_v${KUBECTX_VER}_linux_x86_64.tar.gz" \
            | $SUDO tar -xz -C /usr/local/bin/ kubectx 2>/dev/null && \
           curl -fsSL "${BASE}/kubens_v${KUBECTX_VER}_linux_x86_64.tar.gz" \
            | $SUDO tar -xz -C /usr/local/bin/ kubens 2>/dev/null; then
            success "kubectx + kubens ${KUBECTX_VER} installed"
            mark_installed "kubectx/kubens"
        else
            warn "kubectx install failed"
            mark_failed "kubectx/kubens"
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
    $SUDO apt-get update -qq
    if $SUDO apt-get install -y -qq terraform &>/dev/null; then
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
    $SUDO apt-get install -y -qq software-properties-common &>/dev/null
    if $SUDO apt-get install -y -qq ansible &>/dev/null; then
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
read -rp "$(echo -e "${PINK}  Install AWS CLI? [y/N]:${R} ")" install_aws
if [[ "${install_aws,,}" == "y" ]]; then
    if check_tool "aws-cli" "aws"; then :
    else
        info "Installing AWS CLI v2..."
        curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
            -o /tmp/awscliv2.zip 2>/dev/null
        unzip -q /tmp/awscliv2.zip -d /tmp/
        if $SUDO /tmp/aws/install &>/dev/null; then
            success "AWS CLI v2 installed"
            mark_installed "aws-cli"
        else
            error "AWS CLI install failed"
            mark_failed "aws-cli"
        fi
        rm -rf /tmp/aws /tmp/awscliv2.zip
    fi
else
    echo -e "${GREY}  ↷  AWS CLI — skipped by user${R}"
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
read -rp "$(echo -e "${PINK}  Install Starship prompt? [y/N]:${R} ")" install_starship
if [[ "${install_starship,,}" == "y" ]]; then
    if check_tool "starship"; then :
    else
        info "Installing starship..."
        if curl -fsSL https://starship.rs/install.sh | sh -s -- --yes &>/dev/null; then
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
    fi
else
    echo -e "${GREY}  ↷  starship — skipped by user${R}"
fi


# ── 8b. NERD FONTS (optional) ───────────────────────────────────
echo ""
read -rp "$(echo -e "${PINK}  Install JetBrainsMono Nerd Font? [y/N]:${R} ")" install_fonts
if [[ "${install_fonts,,}" == "y" ]]; then
    info "Installing JetBrainsMono Nerd Font to ~/.local/share/fonts..."
    mkdir -p "$HOME/.local/share/fonts"
    TEMP_ZIP="/tmp/JetBrainsMonoNerd.zip"
    if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip" -o "$TEMP_ZIP"; then
        if unzip -o "$TEMP_ZIP" -d "$HOME/.local/share/fonts" &>/dev/null; then
            fc-cache -fv "$HOME/.local/share/fonts" &>/dev/null || true
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
                    if unzip -o "$TEMP_ZIP" -d "$HOME/.local/share/fonts" &>/dev/null; then
                        fc-cache -fv "$HOME/.local/share/fonts" &>/dev/null || true
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
                    if unzip -o "$TEMP_ZIP" -d "$HOME/.local/share/fonts" &>/dev/null; then
                        fc-cache -fv "$HOME/.local/share/fonts" &>/dev/null || true
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


# ── 9. SUMMARY ───────────────────────────────────────────────────
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

# ── Install .bashrc (deferred) ───────────────────────────────────
section "Applying .bashrc"

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BASHRC_SRC="${SCRIPT_DIR}/bashrc"

if [[ -f "$BASHRC_SRC" ]]; then
    BACKUP_PATH="${HOME}/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    if [[ -f "$HOME/.bashrc" ]]; then
        cp "$HOME/.bashrc" "$BACKUP_PATH" 2>/dev/null || true
        success "Original ~/.bashrc backed up  →  ${BACKUP_PATH}"
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

