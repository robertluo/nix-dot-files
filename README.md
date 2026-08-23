# ~/.nix — Home Manager Configuration

This repository contains my [Home Manager](https://github.com/nix-community/home-manager) configuration for macOS (Apple Silicon / `aarch64-darwin`), declaratively managing the shell environment, editor tooling, CLI packages, and dotfiles.

## Inputs

| Input | Source | Purpose |
|---|---|---|
| `nixpkgs` | `github:NixOS/nixpkgs/nixos-26.05` | Primary package set |
| `home-manager` | `github:nix-community/home-manager/release-26.05` | Home Manager module system |
| `nixpkgs-neovim` | `github:NixOS/nixpkgs/832efc09` | Pinned Neovim 0.11.2 |

## Structure

```
.
├── flake.nix           # Flake entry point; defines home configuration
├── home.nix            # Home Manager module (programs, packages, dotfiles)
├── devenv.nix          # devenv dev-environment config (hooks, scripts)
├── devenv.yaml         # devenv inputs (nixpkgs rolling, git-hooks.nix)
├── README.md           # This file
└── dotfiles/
    └── nvim/           # Neovim config, symlinked to ~/.config/nvim
        ├── init.lua    # Entry point (lazy.nvim bootstrap + require)
        ├── lua/
        │   ├── config/       # Core, keymaps, options
        │   └── plugins/      # Lazy plugin specs
        └── snippets/         # Language snippets (Go, Lua, Python, Rust, TS, etc.)
```

## Key Configuration

### Programs

- **Shell:** Fish (primary) with bash available as fallback
- **Terminal:** Ghostty (`ghostty-bin`) — font size 14, background opacity 0.95
- **Editor:** Neovim 0.11.2 (pinned via separate `nixpkgs-neovim` input)
- **GUI Editor:** Neovide

### Packages

git, jujutsu, ripgrep, babashka, devenv, mosh, GitHub CLI, curl, doctl, nixd, deadnix, statix

### Neovim Plugins

lazy.nvim, telescope, nvim-treesitter, nvim-lspconfig, nvim-cmp, nvim-autopairs, nvim-ts-autotag, nvim-treesitter-textobjects, nvim-tree-lua, gitsigns, nvim-web-devicons, dressing.nvim, which-key, indent-blankline, todo-comments, noice.nvim, lualine, nvim-navic, nvim-scrollbar, nvim-lightbulb, lspkind, friendly-snippets

## Commands

Enter the dev environment first:

```bash
devenv shell
```

Then run:

| Script | Command | Description |
|---|---|---|
| `apply` | `home-manager switch --flake .#tianluo` | Apply home config |
| `update` | `nix flake update` | Refresh pinned inputs |
| `check` | `home-manager build --flake .#tianluo` | Validate without applying |
| `update-readme` | *(runs this script)* | Update this README |

## Pre-commit Hooks

Configured via `devenv.nix` using `git-hooks.nix`:

- **shellcheck** — lint shell scripts
- **statix** — lint Nix code

## Conventions

- Target platform is `aarch64-darwin` (Apple Silicon macOS)
- `home.stateVersion` is `26.05`, matching the Home Manager release
- Neovim is pinned via a separate `nixpkgs-neovim` input to avoid version drift
- The `.gitignore` excludes devenv/direnv/pre-commit local files (e.g. `.devenv*`, `.direnv`)
