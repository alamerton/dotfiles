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
log() { echo "[$(date '+%H:%M:%S')] $1"; }
log_section() { echo ""; echo "=== $1 ==="; }

# --- Miniconda ---
install_miniconda() {
    log_section "Miniconda"
    if [ -d "$CONDA_DIR" ]; then
        log "Already installed at $CONDA_DIR"
        return 0
    fi
    
    cd /workspace
    [ ! -f "Miniconda3-latest-Linux-x86_64.sh" ] && \
        wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -u -b -p "$CONDA_DIR"
    log "Installed"
}

setup_conda() {
    export PATH="$CONDA_DIR/bin:$PATH"
    eval "$($CONDA_DIR/bin/conda shell.bash hook)"
    $CONDA_DIR/bin/conda init bash 2>/dev/null
}

# --- Conda Environment ---
setup_conda_env() {
    log_section "Conda Environment: $CONDA_ENV"
    
    if ! conda env list | grep -q "^${CONDA_ENV} "; then
        log "Creating environment..."
        conda create -n "$CONDA_ENV" python=3.12 pip -y -c conda-forge
    fi
    
    conda activate "$CONDA_ENV"
    
    # Check Python exists
    if [ ! -f "$CONDA_DIR/envs/$CONDA_ENV/bin/python" ]; then
        log "Python missing, reinstalling..."
        conda install -n "$CONDA_ENV" python=3.12 pip -y -c conda-forge
    fi
    
    # Check packages
    if [ -f "$REQUIREMENTS" ]; then
        PKG_COUNT=$(pip list 2>/dev/null | wc -l)
        if [ "$PKG_COUNT" -lt 50 ]; then
            log "Few packages ($PKG_COUNT), installing from requirements..."
            pip install -r "$REQUIREMENTS"
        else
            log "Environment ready ($PKG_COUNT packages)"
        fi
    fi
}

# --- System Packages ---
install_system_packages() {
    log_section "System Packages"
    
    local packages_to_install=()
    
    command -v nvim &>/dev/null || packages_to_install+=(neovim)
    command -v tmux &>/dev/null || packages_to_install+=(tmux)
    command -v rg &>/dev/null || packages_to_install+=(ripgrep)
    command -v fd &>/dev/null || packages_to_install+=(fd-find)
    
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        sudo apt update -qq
        sudo apt install -y "${packages_to_install[@]}"
        log "Installed: ${packages_to_install[*]}"
    else
        log "All packages present"
    fi
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
        conda install -y -c conda-forge 'nodejs>=20'
        hash -r
        log "Node.js installed ($(node --version))"
    else
        log "Node.js present ($(node --version))"
    fi

    if ! command -v claude &>/dev/null; then
        npm install -g @anthropic-ai/claude-code
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
}

# Install Cursor extensions
if command -v cursor &>/dev/null && [ -f "$DOTFILES_DIR/config/cursor-extensions.txt" ]; then
    while read -r ext; do
        cursor --install-extension "$ext"
    done < "$DOTFILES_DIR/config/cursor-extensions.txt"
fi

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
    
    install_miniconda
    setup_conda
    setup_conda_env
    install_system_packages
    install_node_claude
    deploy_configs
    setup_git
    
    # Navigate to project
    [ -d "$PROJECT_DIR" ] && cd "$PROJECT_DIR"
    
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║     Setup Complete                     ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Run: source ~/.bashrc && conda activate $CONDA_ENV"
}

main "$@"
