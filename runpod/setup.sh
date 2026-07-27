#!/bin/bash
# RunPod Network Volume Startup Script
# Refactored for dotfiles integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env_vars.sh"

# RunPod runs as root; sudo is unnecessary and often absent
if [ "$(id -u)" -eq 0 ] || ! command -v sudo &>/dev/null; then
    sudo() {
        while [[ "$1" == -* ]]; do shift; done
        "$@"
    }
fi

# apt must never stop to ask a question. Set it here rather than prefixing
# apt-get calls, because the sudo shim above runs "$@" directly and would treat
# a VAR=value prefix as a command name.
export DEBIAN_FRONTEND=noninteractive

log() { echo "[$(date '+%H:%M:%S')] $1"; }
log_section() { echo ""; echo "=== $1 ==="; }

# Without this, `set -e` aborts with no clue as to which step died
trap 'ec=$?; echo ""; echo "!!! setup.sh failed at line $LINENO (exit $ec)" >&2' ERR

# --- Miniconda ---
conda_works() {
    [ -x "$CONDA_DIR/bin/conda" ] && "$CONDA_DIR/bin/conda" --version &>/dev/null
}

install_miniconda() {
    log_section "Miniconda"
    if conda_works; then
        log "Already installed at $CONDA_DIR ($("$CONDA_DIR/bin/conda" --version))"
        return 0
    fi

    # A directory alone is not proof of a working install. On the network
    # volume this install takes ~25 minutes, so it is easy to interrupt and
    # end up with a half-extracted tree that has no bin/conda in it.
    if [ -d "$CONDA_DIR" ]; then
        log "Partial install found at $CONDA_DIR, removing it"
        rm -rf "$CONDA_DIR"
    fi

    cd /workspace
    local installer="Miniconda3-latest-Linux-x86_64.sh"
    if [ ! -f "$installer" ] || [ "$(stat -c %s "$installer")" -lt 50000000 ]; then
        log "Downloading $installer..."
        rm -f "$installer"
        wget -q "https://repo.anaconda.com/miniconda/$installer"
    fi

    log "Installing to $CONDA_DIR (~25 min on the network volume, no output until done)"
    bash "$installer" -u -b -p "$CONDA_DIR"
    conda_works || { echo "conda is still missing after install" >&2; return 1; }
    log "Installed"
}

setup_conda() {
    export PATH="$CONDA_DIR/bin:$PATH"
    eval "$($CONDA_DIR/bin/conda shell.bash hook)"
    # Noisy "no change" listing on every re-run, and $HOME is not on the
    # volume so this has to run again on each new pod regardless
    $CONDA_DIR/bin/conda init bash >/dev/null 2>&1
}

# --- Conda Channels ---
# Miniconda ships with Anaconda's own channels (pkgs/main, pkgs/r) enabled.
# Since conda 25 they refuse to solve non-interactively until their Terms of
# Service are accepted, which kills this script with CondaToSNonInteractiveError,
# and they carry commercial-use restrictions on top. Every package here comes
# from conda-forge anyway, so drop the defaults rather than accept the ToS.
configure_conda_channels() {
    log_section "Conda Channels"

    # Read the file directly first - every `conda config` call costs several
    # seconds of interpreter startup off the network volume
    if grep -q 'conda-forge' "$CONDA_DIR/.condarc" 2>/dev/null &&
        ! grep -q 'defaults' "$CONDA_DIR/.condarc" 2>/dev/null; then
        log "Already restricted to conda-forge"
        return 0
    fi

    conda config --system --add channels conda-forge
    conda config --system --remove channels defaults 2>/dev/null || true
    conda config --system --set channel_priority strict
    log "Restricted to conda-forge ($CONDA_DIR/.condarc)"
}

# --- Conda Environment ---
setup_conda_env() {
    log_section "Conda Environment: $CONDA_ENV"

    # Match the env name column exactly - a bare grep also matches any env
    # whose path happens to contain the name
    if ! conda env list | awk '{print $1}' | grep -qx "$CONDA_ENV"; then
        log "Creating environment..."
        conda create -n "$CONDA_ENV" python=3.12 pip -y --override-channels -c conda-forge
    fi

    conda activate "$CONDA_ENV"

    # Check Python exists
    if [ ! -f "$CONDA_DIR/envs/$CONDA_ENV/bin/python" ]; then
        log "Python missing, reinstalling..."
        conda install -n "$CONDA_ENV" python=3.12 pip -y --override-channels -c conda-forge
    fi

    # Check packages
    if [ -f "$REQUIREMENTS" ]; then
        PKG_COUNT=$(pip list 2>/dev/null | wc -l)
        if [ "$PKG_COUNT" -lt 50 ]; then
            log "Few packages ($PKG_COUNT), installing from $REQUIREMENTS..."
            pip install -r "$REQUIREMENTS"
        else
            log "Environment ready ($PKG_COUNT packages)"
        fi
    else
        log "No requirements file at $REQUIREMENTS, skipping pip install"
    fi
}

# --- System Packages ---
install_system_packages() {
    log_section "System Packages"

    local packages_to_install=()

    command -v tmux &>/dev/null || packages_to_install+=(tmux)
    command -v rg &>/dev/null || packages_to_install+=(ripgrep)
    # Ubuntu's fd-find installs the binary as `fdfind`, so probing for `fd`
    # would reinstall the package on every run
    command -v fdfind &>/dev/null || packages_to_install+=(fd-find)
    command -v jq &>/dev/null || packages_to_install+=(jq)
    command -v htop &>/dev/null || packages_to_install+=(htop)

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${packages_to_install[@]}"
        log "Installed: ${packages_to_install[*]}"
    else
        log "All packages present"
    fi

    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        ln -sf "$(command -v fdfind)" /usr/local/bin/fd
        log "Linked fdfind -> fd"
    fi
}

# --- Neovim ---
# The base image's apt neovim is 0.4.x, which cannot read config/nvim/init.lua
# (vim.keymap.set and laststatus=3 both need >= 0.7), so install a current
# build under $TOOLS_DIR instead of `apt install neovim`.
NVIM_VERSION="v0.9.5"

nvim_is_current() {
    command -v nvim &>/dev/null || return 1
    local version major minor
    version=$(nvim --version | head -1 | sed -E 's/^NVIM v?([0-9]+\.[0-9]+).*/\1/')
    major=${version%%.*}
    minor=${version#*.}
    [ "$major" -gt 0 ] || [ "$minor" -ge 7 ]
}

install_neovim() {
    log_section "Neovim"

    # The binary lives on the volume but /usr/local/bin does not, so a fresh
    # pod needs the symlink put back rather than a fresh download
    if [ -x "$TOOLS_DIR/nvim-linux64/bin/nvim" ] && ! command -v nvim &>/dev/null; then
        ln -sf "$TOOLS_DIR/nvim-linux64/bin/nvim" /usr/local/bin/nvim
        hash -r
        log "Relinked existing install from $TOOLS_DIR"
    fi

    if nvim_is_current; then
        log "Present ($(nvim --version | head -1))"
        return 0
    fi

    local tarball="nvim-linux64.tar.gz"
    local url="https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/$tarball"

    mkdir -p "$TOOLS_DIR"
    cd "$TOOLS_DIR"
    log "Installing neovim $NVIM_VERSION..."
    rm -rf nvim-linux64
    wget -q "$url"
    tar xzf "$tarball"
    rm -f "$tarball"
    ln -sf "$TOOLS_DIR/nvim-linux64/bin/nvim" /usr/local/bin/nvim
    hash -r
    log "Installed ($(nvim --version | head -1))"
}

# --- Node.js & Claude Code ---
# Install via conda so node lives on /workspace and survives pod restarts.
# Claude Code's postinstall uses optional chaining, so node must be >= 18.
install_node_claude() {
    log_section "Node.js & Claude Code"

    local min_major=18
    local current_major=0
    if command -v node &>/dev/null; then
        current_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
    fi

    if [ "$current_major" -lt "$min_major" ]; then
        conda install -y --override-channels -c conda-forge 'nodejs>=20'
        hash -r
        log "Node.js installed ($(node --version))"
    else
        log "Node.js present ($(node --version))"
    fi

    if ! command -v claude &>/dev/null; then
        npm install -g @anthropic-ai/claude-code
        hash -r
        log "Claude Code installed"
    else
        log "Claude Code present"
    fi
}

# --- Configs ---
deploy_configs() {
    log_section "Deploying Configs"

    local config_dir="$DOTFILES_DIR/config"

    # tmux
    if [ -f "$config_dir/tmux.conf" ]; then
        cp "$config_dir/tmux.conf" ~/.tmux.conf
        log "tmux.conf deployed"
    fi

    # neovim
    if [ -d "$config_dir/nvim" ]; then
        mkdir -p ~/.config
        rm -rf ~/.config/nvim
        ln -sf "$config_dir/nvim" ~/.config/nvim
        log "nvim config linked"
    fi

    # aliases - append to bashrc if not already present
    if [ -f "$config_dir/aliases.sh" ]; then
        if ! grep -q "source.*aliases.sh" ~/.bashrc 2>/dev/null; then
            echo "source $config_dir/aliases.sh" >> ~/.bashrc
            log "aliases.sh added to .bashrc"
        else
            log "aliases.sh already sourced"
        fi
    fi

    # Start new shells in the project env rather than base. This has to land
    # after the conda init block that setup_conda appended.
    if ! grep -q "conda activate $CONDA_ENV" ~/.bashrc 2>/dev/null; then
        echo "conda activate $CONDA_ENV" >> ~/.bashrc
        log "auto-activate $CONDA_ENV added to .bashrc"
    fi
}

install_cursor_extensions() {
    if command -v cursor &>/dev/null && [ -f "$DOTFILES_DIR/config/cursor-extensions.txt" ]; then
        log_section "Cursor Extensions"
        while read -r ext; do
            cursor --install-extension "$ext"
        done < "$DOTFILES_DIR/config/cursor-extensions.txt"
    fi
}

# --- Git ---
setup_git() {
    log_section "Git"
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    log "Configured as $GIT_USER_NAME <$GIT_USER_EMAIL>"
}

# --- Main ---
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║     RunPod Environment Setup           ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "A first run on an empty network volume takes 30-45 minutes."
    echo "Run it under tmux so a dropped terminal cannot kill it:"
    echo "  tmux new -s setup '$SCRIPT_DIR/setup.sh 2>&1 | tee /workspace/setup.log'"
    echo "Re-running afterwards is cheap - every step is skipped if already done."

    install_miniconda
    setup_conda
    configure_conda_channels
    setup_conda_env
    install_system_packages
    install_neovim
    install_node_claude
    deploy_configs
    install_cursor_extensions
    setup_git

    # Navigate to project
    [ -d "$PROJECT_DIR" ] && cd "$PROJECT_DIR"

    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║     Setup Complete                     ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Project: $PROJECT_DIR"
    echo "Run: source ~/.bashrc && conda activate $CONDA_ENV"
}

main "$@"
