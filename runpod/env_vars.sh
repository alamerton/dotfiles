#!/bin/bash
# RunPod Environment Variables
# Centralized configuration for runpod setup

# Conda
export CONDA_DIR="${CONDA_DIR:-/workspace/miniconda}"
export CONDA_ENV="${CONDA_ENV:-sl}"

# Tools that are too old in the base image get installed here instead
export TOOLS_DIR="${TOOLS_DIR:-/workspace/tools}"

# Project paths - first candidate that exists wins, override by exporting
# PROJECT_DIR before running setup.sh
if [ -z "$PROJECT_DIR" ]; then
    for _candidate in \
        /workspace/secret-loyalties \
        /workspace/Secret-Loyalty-Pilot \
        /workspace/Secret-Loyalties; do
        if [ -d "$_candidate" ]; then
            PROJECT_DIR="$_candidate"
            break
        fi
    done
fi
export PROJECT_DIR="${PROJECT_DIR:-/workspace/secret-loyalties}"

# Requirements file - first candidate that exists wins
if [ -z "$REQUIREMENTS" ]; then
    for _req in \
        "$PROJECT_DIR/requirements_clean.txt" \
        "$PROJECT_DIR/requirements.txt"; do
        if [ -f "$_req" ]; then
            REQUIREMENTS="$_req"
            break
        fi
    done
fi
export REQUIREMENTS="${REQUIREMENTS:-$PROJECT_DIR/requirements.txt}"

# Git
export GIT_USER_NAME="Alfie"
export GIT_USER_EMAIL="alfie.david.lamerton@gmail.com"

# Dotfiles
export DOTFILES_DIR="${DOTFILES_DIR:-/workspace/dotfiles}"
