# ╔══════════════════════════════════════════════════════════════╗
# ║              ~/.bashrc  —  Crafted for DevOps Power          ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Guard: interactive shell only ────────────────────────────────
case $- in
    *i*) ;;
      *) return;;
esac


# ╔══════════════════════════════════════════════════════════════╗
# ║  HISTORY                                                     ║
# ╚══════════════════════════════════════════════════════════════╝
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
HISTTIMEFORMAT="%F %T  "
shopt -s histappend
shopt -s checkwinsize
shopt -s globstar
shopt -s autocd          # type a dir name to cd into it
shopt -s cdspell         # auto-correct minor typos in cd

# Save history after every command (multi-terminal safe)
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"


# ╔══════════════════════════════════════════════════════════════╗
# ║  COLORS & THEME  (Nord-Cyberpunk palette)                    ║
# ╚══════════════════════════════════════════════════════════════╝
# Reset
R='\[\e[0m\]'

# Regular
BLACK='\[\e[0;30m\]';  RED='\[\e[0;31m\]';    GREEN='\[\e[0;32m\]'
YELLOW='\[\e[0;33m\]'; BLUE='\[\e[0;34m\]';   PURPLE='\[\e[0;35m\]'
CYAN='\[\e[0;36m\]';   WHITE='\[\e[0;37m\]'

# Bold
BBLACK='\[\e[1;30m\]'; BRED='\[\e[1;31m\]';   BGREEN='\[\e[1;32m\]'
BYELLOW='\[\e[1;33m\]';BBLUE='\[\e[1;34m\]';  BPURPLE='\[\e[1;35m\]'
BCYAN='\[\e[1;36m\]';  BWHITE='\[\e[1;37m\]'

# 256-color accents
NORD_BLUE='\[\e[38;5;67m\]'
NORD_CYAN='\[\e[38;5;110m\]'
NORD_GREEN='\[\e[38;5;108m\]'
NEON_PINK='\[\e[38;5;205m\]'
NEON_CYAN='\[\e[38;5;45m\]'
NEON_GREEN='\[\e[38;5;82m\]'
ORANGE='\[\e[38;5;214m\]'
GOLD='\[\e[38;5;220m\]'
GREY='\[\e[38;5;244m\]'
DIM='\[\e[2m\]'


# ╔══════════════════════════════════════════════════════════════╗
# ║  PROMPT                                                      ║
# ╚══════════════════════════════════════════════════════════════╝
# Load git prompt helper
[[ -f /usr/lib/git-core/git-sh-prompt ]] && source /usr/lib/git-core/git-sh-prompt

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM="auto"
GIT_PS1_SHOWCOLORHINTS=1

# Exit-code indicator
__exit_status() {
    local code=$?
    if [[ $code -eq 0 ]]; then
        echo -e "\e[38;5;82m✔\e[0m"
    else
        echo -e "\e[38;5;196m✘ $code\e[0m"
    fi
}

# K8s context (only if kubectl exists)
__kube_ctx() {
    command -v kubectl &>/dev/null || return
    local ctx ns
    ctx=$(kubectl config current-context 2>/dev/null) || return
    ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
    ns="${ns:-default}"
    echo -e " \e[38;5;69m⎈ ${ctx}:${ns}\e[0m"
}

# Terraform workspace (only inside a tf dir)
__tf_workspace() {
    [[ -d .terraform ]] || return
    command -v terraform &>/dev/null || return
    local ws
    ws=$(terraform workspace show 2>/dev/null) || return
    echo -e " \e[38;5;99m✦ tf:${ws}\e[0m"
}

# Python venv
__venv() {
    [[ -n "$VIRTUAL_ENV" ]] && echo -e " \e[38;5;214m🐍 $(basename $VIRTUAL_ENV)\e[0m"
}

# Node version (only in dirs with package.json)
__node_ver() {
    [[ -f package.json ]] || return
    command -v node &>/dev/null || return
    echo -e " \e[38;5;40m⬡ $(node -v)\e[0m"
}

# Build the prompt
__build_ps1() {
    local exit_code=$?

    # Line 1: ┌ user@host  path  git  extras
    local user_host="${NEON_CYAN}\u${GREY}@${NORD_CYAN}\h${R}"
    local path="${BBLUE}\w${R}"
    local git_info
    git_info=$(
        __git_ps1 " ${NEON_PINK} %s${R}" 2>/dev/null
    )
    local extras
    extras="$(__kube_ctx)$(__tf_workspace)$(__venv)$(__node_ver)"

    # Exit indicator
    local status_icon
    if [[ $exit_code -eq 0 ]]; then
        status_icon="${NEON_GREEN}✔${R}"
    else
        status_icon="${BRED}✘ ${exit_code}${R}"
    fi

    # Time
    local ts="${GREY}$(date +%H:%M:%S)${R}"

    PS1="\n${GREY}┌─[${R}${ts}${GREY}]─[${R}${status_icon}${GREY}]── ${R}${user_host}${GREY} in ${R}${path}${git_info}${extras}\n${GREY}└─${R}${NEON_PINK}❯${NEON_CYAN}❯${NEON_GREEN}❯${R} "
}

PROMPT_COMMAND="__build_ps1; history -a; history -c; history -r"


# ╔══════════════════════════════════════════════════════════════╗
# ║  PATH                                                        ║
# ╚══════════════════════════════════════════════════════════════╝
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.krew/bin:/usr/local/bin:$PATH"

# Go
[[ -d /usr/local/go/bin ]] && export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
# Rust/Cargo
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
# Python user installs
[[ -d "$HOME/.local/lib" ]] && export PYTHONPATH="$HOME/.local/lib/python3/dist-packages:$PYTHONPATH"
# npm global
export PATH="$HOME/.npm-global/bin:$PATH"
export NPM_CONFIG_PREFIX="$HOME/.npm-global"


# ╔══════════════════════════════════════════════════════════════╗
# ║  ENVIRONMENT                                                 ║
# ╚══════════════════════════════════════════════════════════════╝
export EDITOR="nano"
export VISUAL="nano"
export PAGER="less"
export LESS="-RFX"                 # colors, quit if one screen, no alt screen
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export COLORTERM="truecolor"
export TERM="${TERM:-xterm-256color}"
export DOCKER_BUILDKIT=1           # always use BuildKit
export COMPOSE_DOCKER_CLI_BUILD=1


# ╔══════════════════════════════════════════════════════════════╗
# ║  LESSPIPE + DIRCOLORS                                        ║
# ╚══════════════════════════════════════════════════════════════╝
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi


# ╔══════════════════════════════════════════════════════════════╗
# ║  MODERN TOOL ALIASES (eza, bat, btop)                        ║
# ╚══════════════════════════════════════════════════════════════╝

 # Detect whether a Nerd Font is installed (used for icons). If not,
 # fall back to non-icon aliases for a clean terminal appearance.
DEVOPS_USE_ICONS=0
if command -v fc-list &>/dev/null; then
    if fc-list | grep -i 'nerd' &>/dev/null || fc-list | grep -i 'jetbrains' &>/dev/null; then
        DEVOPS_USE_ICONS=1
    fi
else
    if [[ -d "$HOME/.local/share/fonts" ]] && ls "$HOME/.local/share/fonts" | grep -i 'nerd' &>/dev/null; then
        DEVOPS_USE_ICONS=1
    fi
fi

# Function to (re)define the ls aliases based on current DEVOPS_USE_ICONS
set_icon_aliases() {
    if command -v eza &>/dev/null; then
        if [[ "$DEVOPS_USE_ICONS" -eq 1 ]]; then
            alias ls='eza --icons --group-directories-first'
            alias ll='eza -lah --icons --group-directories-first --git'
            alias la='eza -a --icons'
            alias lt='eza -T --icons --git-ignore'
            alias llt='eza -lT --icons --git-ignore'
            alias l='eza -1 --icons'
        else
            alias ls='eza --group-directories-first'
            alias ll='eza -lah --group-directories-first --git'
            alias la='eza -a'
            alias lt='eza -T --git-ignore'
            alias llt='eza -lT --git-ignore'
            alias l='eza -1'
        fi
    else
        alias ls='ls --color=auto'
        alias ll='ls -alF'
        alias la='ls -A'
        alias l='ls -CF'
    fi
}

# Helpers to toggle icons at runtime
enable_icons() {
    DEVOPS_USE_ICONS=1
    set_icon_aliases
    echo "Icons enabled (aliases updated). If your terminal font supports icons, they will display now."
}

disable_icons() {
    DEVOPS_USE_ICONS=0
    set_icon_aliases
    echo "Icons disabled (aliases updated)."
}

# Test whether icons render correctly in this terminal
test_icons() {
    echo
    echo "Icon glyph test:"
    echo -e "  ⚡        🐚"
    echo
    if command -v eza &>/dev/null; then
        echo "eza preview (first 6 entries):"
        eza -1 --icons --group-directories-first | sed -n '1,6p' || true
    fi
    echo
}

# Initialize aliases now
set_icon_aliases

# bat → syntax-highlighted cat
if command -v batcat &>/dev/null; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
    alias catp='batcat'                         # with paging
elif command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
    alias catp='bat'
fi

# btop > htop > top
if command -v btop &>/dev/null; then
    alias top='btop'
    alias htop='btop'
fi


# ╔══════════════════════════════════════════════════════════════╗
# ║  NAVIGATION                                                  ║
# ╚══════════════════════════════════════════════════════════════╝
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias ~='cd ~'

# zoxide (smart cd with frecency)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
    alias cd='z'       # replaces cd with smart jump
    alias cdi='zi'     # interactive fuzzy picker
fi

# Quick dir bookmarks
alias cdp='cd ~/projects 2>/dev/null || cd ~'
alias cdd='cd ~/Downloads'
alias cdcfg='cd ~/.config'


# ╔══════════════════════════════════════════════════════════════╗
# ║  FZF — Fuzzy Everything                                     ║
# ╚══════════════════════════════════════════════════════════════╝
if command -v fzf &>/dev/null; then
    # Load fzf keybindings and completions
    eval "$(fzf --bash 2>/dev/null)" || {
        [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]] && \
            source /usr/share/doc/fzf/examples/key-bindings.bash
        [[ -f /usr/share/bash-completion/completions/fzf ]] && \
            source /usr/share/bash-completion/completions/fzf
    }

    # Theme — Nord/Cyberpunk
    export FZF_DEFAULT_OPTS="
        --height=50% --layout=reverse --border=rounded
        --color=bg+:#2E3440,bg:#242933,spinner:#81A1C1,hl:#88C0D0
        --color=fg:#D8DEE9,header:#88C0D0,info:#81A1C1,pointer:#BF616A
        --color=marker:#A3BE8C,fg+:#ECEFF4,prompt:#81A1C1,hl+:#88C0D0
        --prompt='❯ ' --pointer='▶' --marker='✓'
        --bind='ctrl-/:toggle-preview'
    "

    # Use fd or find for file search
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # Ctrl-R → beautiful fuzzy history search
    # Ctrl-T → fuzzy file finder
    # Alt-C  → fuzzy cd

    # ff: fuzzy find & open file
    ff() { fzf --preview 'batcat --color=always {} 2>/dev/null || cat {}' | xargs -r "${EDITOR:-vim}"; }

    # fcd: fuzzy cd into any dir
    fcd() {
        local dir
        dir=$(find "${1:-.}" -type d 2>/dev/null | fzf --preview 'eza -la --icons {}') && cd "$dir"
    }

    # fkill: fuzzy kill process
    fkill() {
        local pid
        pid=$(ps aux | tail -n +2 | fzf --multi | awk '{print $2}')
        [[ -n "$pid" ]] && echo "$pid" | xargs kill -${1:-15}
    }

    # fenv: fuzzy search env vars
    fenv() { printenv | sort | fzf; }

    # fh: fuzzy search history and run
    fh() {
        local cmd
        cmd=$(history | awk '{$1=""; print substr($0,2)}' | sort -u | fzf --tac)
        [[ -n "$cmd" ]] && eval "$cmd"
    }
fi


# ╔══════════════════════════════════════════════════════════════╗
# ║  GIT                                                         ║
# ╚══════════════════════════════════════════════════════════════╝
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gca='git commit --amend --no-edit'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gb='git branch -vv'
alias gba='git branch -avv'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate --all'
alias gll='git log --graph --pretty=format:"%C(auto)%h%d %s %C(dim)%cr by %an" --all'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull --rebase'
alias gf='git fetch --all --prune'
alias gr='git rebase'
alias gri='git rebase -i'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gtag='git tag -l | sort -V'
alias greset='git reset --hard HEAD'
alias gclean='git clean -fd'

# glg: pretty log with colors
glg() {
    git log --graph \
        --pretty=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)— %an%C(reset)%C(bold yellow)%d%C(reset)' \
        --abbrev-commit --all "$@"
}

# gundo: undo last commit (keep changes staged)
alias gundo='git reset --soft HEAD~1'

# gnew: init a new repo and first commit
gnew() {
    git init && git add -A && git commit -m "feat: initial commit"
}


# ╔══════════════════════════════════════════════════════════════╗
# ║  DOCKER                                                      ║
# ╚══════════════════════════════════════════════════════════════╝
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcl='docker compose logs -f'
alias dcb='docker compose build'
alias dcp='docker compose pull'
alias dce='docker compose exec'
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias di='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"'
alias drm='docker rm $(docker ps -aq) 2>/dev/null'        # remove all stopped containers
alias drmi='docker rmi $(docker images -qf dangling=true) 2>/dev/null'  # remove dangling images
alias dprune='docker system prune -af --volumes'

# dsh: shell into a running container
dsh() { docker exec -it "${1}" ${2:-/bin/bash}; }

# dlogs: follow logs with optional tail
dlogs() { docker logs -f --tail="${2:-100}" "$1"; }

# dip: get container IP
dip() { docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"; }

# dstats: live stats
alias dstats='docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"'


# ╔══════════════════════════════════════════════════════════════╗
# ║  KUBERNETES                                                  ║
# ╚══════════════════════════════════════════════════════════════╝
if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    alias kx='kubectl config use-context'       # switch context
    alias kns='kubectl config set-context --current --namespace'  # switch namespace
    alias kctx='kubectl config get-contexts'
    alias kgp='kubectl get pods -o wide'
    alias kgpa='kubectl get pods -A -o wide'
    alias kgs='kubectl get svc -o wide'
    alias kgd='kubectl get deployments -o wide'
    alias kgn='kubectl get nodes -o wide'
    alias kgi='kubectl get ingress'
    alias kgcm='kubectl get configmap'
    alias kgsec='kubectl get secret'
    alias kdp='kubectl describe pod'
    alias kdd='kubectl describe deployment'
    alias kdn='kubectl describe node'
    alias kl='kubectl logs -f'
    alias kla='kubectl logs -f --all-containers=true'
    alias ke='kubectl exec -it'
    alias ka='kubectl apply -f'
    alias kd='kubectl delete'
    alias kdf='kubectl delete -f'
    alias krollout='kubectl rollout status deployment'
    alias krestart='kubectl rollout restart deployment'

    # kshell: shell into a pod
    kshell() { kubectl exec -it "$1" -- ${2:-/bin/sh}; }

    # kwatch: watch pods in namespace
    kwatch() { watch -n2 kubectl get pods "${@:--A}"; }

    # kfwd: port-forward shortcut  kfwd <pod> <local>:<remote>
    kfwd() { kubectl port-forward "$1" "$2"; }

    # Enable kubectl completion
    source <(kubectl completion bash)
    complete -F __start_kubectl k
fi

# Helm
if command -v helm &>/dev/null; then
    alias h='helm'
    alias hl='helm list -A'
    alias hup='helm upgrade --install'
    alias hrm='helm uninstall'
    source <(helm completion bash)
fi


# ╔══════════════════════════════════════════════════════════════╗
# ║  TERRAFORM / OPENTOFU                                        ║
# ╚══════════════════════════════════════════════════════════════╝
if command -v terraform &>/dev/null; then
    alias tf='terraform'
    alias tfi='terraform init'
    alias tfiu='terraform init -upgrade'
    alias tfp='terraform plan'
    alias tfa='terraform apply'
    alias tfaa='terraform apply -auto-approve'
    alias tfd='terraform destroy'
    alias tfda='terraform destroy -auto-approve'
    alias tfo='terraform output'
    alias tfs='terraform state list'
    alias tfv='terraform validate'
    alias tff='terraform fmt -recursive'
    alias tfws='terraform workspace list'
    alias tfwn='terraform workspace new'
    alias tfwx='terraform workspace select'
    complete -C terraform terraform tf
fi

# Ansible
if command -v ansible &>/dev/null; then
    alias ap='ansible-playbook'
    alias ai='ansible-inventory'
    alias ag='ansible-galaxy'
fi


# ╔══════════════════════════════════════════════════════════════╗
# ║  NODE / NPM / BUN                                            ║
# ╚══════════════════════════════════════════════════════════════╝
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nci='npm ci'
alias nls='npm list --depth=0'
alias nlsg='npm list -g --depth=0'
alias nout='npm outdated'
alias nup='npm update'
alias npx='npx --yes'

# pnpm (if installed)
if command -v pnpm &>/dev/null; then
    alias pi='pnpm install'
    alias pr='pnpm run'
    alias pa='pnpm add'
    alias pad='pnpm add -D'
fi


# ╔══════════════════════════════════════════════════════════════╗
# ║  PYTHON                                                      ║
# ╚══════════════════════════════════════════════════════════════╝
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias va='source .venv/bin/activate 2>/dev/null || source venv/bin/activate 2>/dev/null'
alias vd='deactivate'
alias pipr='pip install -r requirements.txt'
alias pipf='pip freeze > requirements.txt'
alias pipu='pip install --upgrade pip'

# mkv: create .venv and activate it
mkv() {
    python3 -m venv "${1:-.venv}" && source "${1:-.venv}/bin/activate"
    echo "✔ venv activated. pip install away."
}


# ╔══════════════════════════════════════════════════════════════╗
# ║  NETWORK / HTTP                                              ║
# ╚══════════════════════════════════════════════════════════════╝
alias myip='curl -s https://ipinfo.io/ip && echo'
alias myips='ip -br a'
alias ports='ss -tulnp'
alias listen='ss -tlnp'

# headers: show HTTP headers
headers() { curl -sI "$1" | bat --language=http --paging=never 2>/dev/null || curl -sI "$1"; }

# httpcheck: status code only
httpcheck() { curl -o /dev/null -s -w "%{http_code}\n" "$1"; }

# sshq: ssh without host key checking (dev only!)
alias sshq='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'


# ╔══════════════════════════════════════════════════════════════╗
# ║  SYSTEM UTILITIES                                            ║
# ╚══════════════════════════════════════════════════════════════╝
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias df='df -hT'
alias du='du -h'
alias duh='du -sh *'               # disk usage of items in current dir
alias free='free -h'
alias ps='ps auxf'
alias psg='ps aux | grep -v grep | grep'
alias reloadrc='source ~/.bashrc && echo "✔ .bashrc reloaded"'
alias editrc='${EDITOR:-vim} ~/.bashrc'
alias path='echo -e "${PATH//:/\\n}"'  # print PATH one entry per line
alias now='date +"%T"'
alias today='date +"%Y-%m-%d"'
alias week='date +"%V"'
alias weather='curl -s wttr.in'    # weather report in terminal!
alias busy='cat /dev/urandom | hexdump -C | grep "ca fe"'  # look busy 😄

# mkcd: make dir and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# extract: universal archive extractor
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)  tar xvjf "$1"   ;;
            *.tar.gz)   tar xvzf "$1"   ;;
            *.tar.xz)   tar xvJf "$1"   ;;
            *.tar)      tar xvf "$1"    ;;
            *.tbz2)     tar xvjf "$1"   ;;
            *.tgz)      tar xvzf "$1"   ;;
            *.zip)      unzip "$1"      ;;
            *.gz)       gunzip "$1"     ;;
            *.bz2)      bunzip2 "$1"    ;;
            *.rar)      unrar x "$1"    ;;
            *.7z)       7z x "$1"       ;;
            *.xz)       unxz "$1"       ;;
            *.Z)        uncompress "$1" ;;
            *)          echo "❌ '$1': unknown archive format" ;;
        esac
    else
        echo "❌ '$1' is not a valid file"
    fi
}

# backup: quick timestamped backup of a file
backup() { cp "$1" "${1}.bak.$(date +%Y%m%d_%H%M%S)"; echo "✔ backed up $1"; }

# up: update everything
up() {
    echo "📦 Updating apt packages..."
    sudo apt-get update -qq && sudo apt-get upgrade -y
    command -v npm &>/dev/null && echo "📦 Updating npm global packages..." && npm update -g
    command -v pip3 &>/dev/null && echo "🐍 Upgrading pip..." && pip3 install --upgrade pip --quiet
    echo "✔ All done!"
}

# serve: quick HTTP server in current dir
serve() { python3 -m http.server "${1:-8000}"; }

# json: pretty-print JSON (stdin or file)
json() {
    if [[ -f "$1" ]]; then
        python3 -m json.tool "$1" | bat --language=json --paging=never 2>/dev/null || python3 -m json.tool "$1"
    else
        python3 -m json.tool | bat --language=json --paging=never 2>/dev/null || python3 -m json.tool
    fi
}

# b64: encode/decode base64
b64()  { echo -n "$1" | base64; }
b64d() { echo -n "$1" | base64 -d; }

# epoch: human-readable unix timestamp
epoch() { date -d "@${1:-$(date +%s)}" 2>/dev/null || date -r "${1:-$(date +%s)}"; }

# sizeof: human-readable file/dir size
sizeof() { du -sh "${1:-.}"; }


# ╔══════════════════════════════════════════════════════════════╗
# ║  WELCOME BANNER                                              ║
# ╚══════════════════════════════════════════════════════════════╝

# Use neofetch for welcome banner if available
if command -v neofetch &>/dev/null; then
    # margin line above neofetch for visual spacing
    printf "\n"
    neofetch
fi


# ╔══════════════════════════════════════════════════════════════╗
# ║  COMPLETIONS                                                 ║
# ╚══════════════════════════════════════════════════════════════╝
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        . /etc/bash_completion
    fi
fi

# git completion
[[ -f /usr/share/bash-completion/completions/git ]] && \
    source /usr/share/bash-completion/completions/git
complete -F __git_wrap__git_main g 2>/dev/null

# docker completion
[[ -f /usr/share/bash-completion/completions/docker ]] && \
    source /usr/share/bash-completion/completions/docker


# ╔══════════════════════════════════════════════════════════════╗
# ║  LOCAL OVERRIDES  (~/.bashrc.local)                          ║
# ╚══════════════════════════════════════════════════════════════╝
# Put machine-specific or secret stuff (API keys, work aliases) here:
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
