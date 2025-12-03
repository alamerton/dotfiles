# dotfiles

Personal dotfiles for RunPod and local development.

## Structure

```
dotfiles/
├── config/
│   ├── aliases.sh      # Shell aliases
│   ├── nvim/           # Neovim configuration
│   │   └── init.lua
│   └── tmux.conf       # tmux configuration
├── runpod/
│   ├── env_vars.sh     # Environment variables
│   └── setup.sh        # Full RunPod setup script
├── deploy.sh           # Symlink configs to home
└── README.md
```

## Usage

### RunPod (full setup)

```bash
git clone https://github.com/alamerton/dotfiles /workspace/dotfiles
cd /workspace/dotfiles
chmod +x runpod/setup.sh
./runpod/setup.sh
```

### Local/existing machine (configs only)

```bash
git clone https://github.com/alamerton/dotfiles ~/dotfiles
cd ~/dotfiles
chmod +x deploy.sh
./deploy.sh
```

## Customization

Edit `runpod/env_vars.sh` to change:
- Conda environment name
- Project directory
- Git user info

## Key bindings

### tmux
- `prefix + h/j/k/l` — pane navigation
- `prefix + H/J/K/L` — pane resize
- `prefix + r` — reload config

### neovim
- `<Space>` — leader key
- `<leader>e` — file explorer
- `<leader>w` — save
- `<leader>q` — quit
- `<C-h/j/k/l>` — window navigation
- `<S-h/l>` — buffer prev/next
