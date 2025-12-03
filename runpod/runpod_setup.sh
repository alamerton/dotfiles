#!/bin/bash
# RunPod Network Volume Startup Script
# This script sets up the development environment on RunPod startup

set -e  # Exit on error

echo "=========================================="
echo "Starting RunPod environment setup..."
echo "=========================================="

# 1. Install Miniconda if not already installed
if [ ! -d "/workspace/miniconda" ]; then
    echo "Installing Miniconda..."
    cd /workspace
    if [ ! -f "Miniconda3-latest-Linux-x86_64.sh" ]; then
        echo "Downloading Miniconda installer..."
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -q
    fi
    bash Miniconda3-latest-Linux-x86_64.sh -u -b -p /workspace/miniconda
    echo "Miniconda installed successfully"
else
    echo "Miniconda already installed, skipping..."
fi

# 2. Set up conda in PATH and initialize
echo "Setting up conda..."
export PATH="/workspace/miniconda/bin:$PATH"
eval "$(/workspace/miniconda/bin/conda shell.bash hook)"

# Initialize conda for bash (this modifies ~/.bashrc)
/workspace/miniconda/bin/conda init bash

# 3. Activate sl environment and verify it has packages
if conda env list | grep -q "^sl "; then
    echo "Activating sl conda environment..."
    conda activate sl

    # Check if Python exists in the environment
    if [ ! -f "/workspace/miniconda/envs/sl/bin/python" ]; then
        echo "WARNING: sl environment exists but Python is missing!"
        echo "This usually happens after pod restart. Reinstalling Python..."
        conda install -n sl python=3.12 pip -y -c conda-forge
    fi

    # Check if packages are installed
    if [ -f "/workspace/Secret-Loyalty-Pilot/requirements_clean.txt" ]; then
        PKG_COUNT=$(pip list 2>/dev/null | wc -l)
        if [ "$PKG_COUNT" -lt 50 ]; then
            echo "WARNING: sl environment has few packages ($PKG_COUNT). Reinstalling from requirements..."
            pip install -r /workspace/Secret-Loyalty-Pilot/requirements_clean.txt
        else
            echo "sl environment activated with $PKG_COUNT packages"
        fi
    else
        echo "sl environment activated"
    fi
else
    echo "WARNING: sl environment not found. Creating it now..."
    conda create -n sl python=3.12 pip -y -c conda-forge
    conda activate sl
    if [ -f "/workspace/Secret-Loyalty-Pilot/requirements_clean.txt" ]; then
        echo "Installing packages from requirements_clean.txt..."
        pip install -r /workspace/Secret-Loyalty-Pilot/requirements_clean.txt
    fi
fi

# 4. Install Node.js and Claude Code
echo "Installing Node.js and Claude Code..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "Node.js installed successfully"
else
    echo "Node.js already installed, skipping..."
fi

if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    sudo npm install -g @anthropic-ai/claude-code
    echo "Claude Code installed successfully"
else
    echo "Claude Code already installed, skipping..."
fi

# 5. Install Neovim
echo "Installing Neovim..."
if ! command -v nvim &> /dev/null; then
    sudo apt update
    sudo apt install -y neovim
    echo "Neovim installed successfully"
else
    echo "Neovim already installed, skipping..."
fi

# 6. Configure tmux
echo "Setting up tmux configuration..."
cat > ~/.tmux.conf << 'EOF'
set -g default-terminal "screen-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g escape-time 0
set -g mouse on
set -g base-index 1

# Match your Alacritty opacity
set -g status-bg default
set -g status-style bg=default

# Vim navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Split in current directory
bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"

# Catppuccin Mocha colors to match your theme
set -g status-fg "#cdd6f4"
set -g pane-border-style fg="#45475a"
set -g pane-active-border-style fg="#89b4fa"
EOF
echo "Tmux configuration created"

# Install tmux if not present
if ! command -v tmux &> /dev/null; then
    sudo apt install -y tmux
    echo "Tmux installed successfully"
else
    echo "Tmux already installed, config updated"
fi

# 7. Set up Git user configuration
echo "Setting up Git user configuration..."
git config --global user.email "alfie.david.lamerton@gmail.com"
git config --global user.name "Alfie"
echo "Git configured with:"
echo "  Name: $(git config --global user.name)"
echo "  Email: $(git config --global user.email)"

# 8. Navigate to project directory
if [ -d "/workspace/Secret-Loyalty-Pilot" ]; then
    cd /workspace/Secret-Loyalty-Pilot
    echo "Changed directory to Secret-Loyalty-Pilot"
fi

echo "=========================================="
echo "Setup complete! Environment is ready."
echo "=========================================="
echo ""
echo "Important notes:"
echo "- Conda has been initialized in ~/.bashrc"
echo "- You may need to restart your shell or run 'source ~/.bashrc' to use conda commands"
echo "- sl-pilot environment is activated (if it exists)"
echo "- Claude Code is available via 'claude' command"
echo "- Neovim is available via 'nvim' command"
echo ""
echo "To use conda in this session, run:"
echo "  source ~/.bashrc"
echo "  conda activate sl-pilot"

