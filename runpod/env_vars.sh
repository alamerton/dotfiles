#!/bin/bash
# RunPod Environment Variables
# Centralized configuration for runpod setup

# Conda
export CONDA_DIR="/workspace/miniconda"
export CONDA_ENV="sl"

# Project paths
export PROJECT_DIR="/workspace/Secret-Loyalty-Pilot"
export REQUIREMENTS="$PROJECT_DIR/requirements_clean.txt"

# Git
export GIT_USER_NAME="Alfie"
export GIT_USER_EMAIL="alfie.david.lamerton@gmail.com"

# Dotfiles
export DOTFILES_DIR="${DOTFILES_DIR:-/workspace/dotfiles}"
