#!/bin/bash
# Aliases

# --- Navigation ---
alias ..="cd .."
alias ...="cd ../.."
alias ws="cd /workspace"
alias sl="cd /workspace/Secret-Loyalty-Pilot"

# --- Git ---
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline -20"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias gpl="git pull"

# --- Python/Conda ---
alias ca="conda activate"
alias casl="conda activate sl"
alias py="python"
alias ipy="ipython"
alias jl="jupyter lab --ip=0.0.0.0 --allow-root --no-browser"

# --- Editors ---
alias v="nvim"
alias vim="nvim"

# --- tmux ---
alias t="tmux"
alias ta="tmux attach -t"
alias tn="tmux new -s"
alias tl="tmux list-sessions"
alias tk="tmux kill-session -t"

# --- System ---
alias ll="ls -lah"
alias la="ls -la"
alias df="df -h"
alias du="du -sh"
alias free="free -h"

# --- GPU ---
alias nv="nvidia-smi"
alias nvw="watch -n 1 nvidia-smi"
alias gpumem="nvidia-smi --query-gpu=memory.used,memory.total --format=csv"

# --- Project-specific ---
alias petri="python -m petri"
alias pytest="python -m pytest -v"
alias reqs="pip install -r requirements_clean.txt"

# --- Utilities ---
alias reload="source ~/.bashrc"
alias path='echo $PATH | tr ":" "\n"'
alias ports="netstat -tulanp"

# --- Claude ---
alias claude-nonroot="sudo -u alfie /usr/bin/claude"
alias claude-dsp="claude --dangerously-skip-permissions"
