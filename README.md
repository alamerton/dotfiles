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
│   ├── env_vars.sh     # Environment variables (conda env, project paths)
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
tmux new -s setup './runpod/setup.sh 2>&1 | tee /workspace/setup.log'
```

The first run against a fresh network volume takes 30-60 minutes, nearly all of
it Miniconda unpacking ~30k files onto the network filesystem. It prints nothing
while that happens - it is slow, not hung. Run it under tmux so a dropped web
terminal cannot kill it partway and leave a half-installed conda behind.

Re-running is cheap: every step is skipped when already done, so a new pod on
the same volume takes a few minutes. Only the pieces outside `/workspace` need
redoing - apt packages, `~/.bashrc`, `~/.config/nvim`, and the `/usr/local/bin`
symlinks - because `$HOME` is `/root` on the container, not the volume.

Conda is pinned to conda-forge (`--override-channels` plus a `--system`
`.condarc`). Anaconda's own `pkgs/main` and `pkgs/r` channels refuse to solve
non-interactively until their Terms of Service are accepted, which otherwise
kills the script with `CondaToSNonInteractiveError`; nothing here needs them.

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
