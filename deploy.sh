#!/bin/bash
# Deploy dotfiles - creates symlinks and sources configs

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"

log() { echo "[deploy] $1"; }

# --- tmux ---
if [ -f "$CONFIG_DIR/tmux.conf" ]; then
    ln -sf "$CONFIG_DIR/tmux.conf" ~/.tmux.conf
    log "Linked ~/.tmux.conf"
fi

# --- neovim ---
if [ -d "$CONFIG_DIR/nvim" ]; then
    mkdir -p ~/.config
    rm -rf ~/.config/nvim
    ln -sf "$CONFIG_DIR/nvim" ~/.config/nvim
    log "Linked ~/.config/nvim"
fi

# --- aliases ---
if [ -f "$CONFIG_DIR/aliases.sh" ]; then
    BASHRC_LINE="source $CONFIG_DIR/aliases.sh"
    if ! grep -qF "$BASHRC_LINE" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# Dotfiles aliases" >> ~/.bashrc
        echo "$BASHRC_LINE" >> ~/.bashrc
        log "Added aliases.sh to ~/.bashrc"
    else
        log "aliases.sh already in ~/.bashrc"
    fi
fi

# --- zsh support (if using zsh) ---
if [ -f ~/.zshrc ]; then
    ZSHRC_LINE="source $CONFIG_DIR/aliases.sh"
    if ! grep -qF "$ZSHRC_LINE" ~/.zshrc 2>/dev/null; then
        echo "" >> ~/.zshrc
        echo "# Dotfiles aliases" >> ~/.zshrc
        echo "$ZSHRC_LINE" >> ~/.zshrc
        log "Added aliases.sh to ~/.zshrc"
    fi
fi

echo ""
log "Deploy complete. Run 'source ~/.bashrc' to apply."
