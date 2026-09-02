# Nix Home Manager Configuration

Declarative macOS (Apple Silicon) environment managed via [Home Manager](https://github.com/nix-community/home-manager) and [devenv](https://devenv.sh/).

## Overview

| Component       | Version / Source                                              |
|-----------------|---------------------------------------------------------------|
| nixpkgs         | `nixos-unstable` (direct input)                               |
| home-manager    | via [omniflake](https://omniflake.com/docs/using) index       |
| Neovim          | 0.11.2 (pinned via `nixpkgs-neovim` at commit `832efc09`)    |
| Target system   | `aarch64-darwin`                                              |
| Shell           | Fish (with Starship prompt)                                   |
| Terminal        | Ghostty                                                       |

## Directory Structure

```
├── flake.nix          # Flake entry point; pins nixpkgs + omniflake, builds home config
├── home.nix           # Home Manager module (programs, packages, dotfile symlinks)
├── devenv.nix         # devenv dev environment (scripts, hooks, languages)
├── devenv.yaml        # devenv inputs (rolling nixpkgs, git-hooks.nix)
└── dotfiles/
    └── nvim/          # Neovim config (LazyVim-based), symlinked to ~/.config/nvim
        ├── init.lua   # Main entry point
        ├── lua/       # Custom plugins and community config
        ├── snippets/  # VSCode-style snippets (clojure, lua, markdown, global)
        └── ...
```

## Quick Start

```bash
# Enter the dev environment
devenv shell

# Available scripts
apply            # Apply home config (home-manager switch)
update           # Refresh pinned flake inputs (nix flake update)
check            # Validate config without applying (home-manager build)
update-readme    # Regenerate this README via pi-coding-agent
```

## Programs & Tools

Configured in `home.nix`:

- **Shell**: Fish with Starship prompt
- **Editor**: Neovim 0.11.2 (LazyVim framework, pinned separately to avoid drift)
- **Terminal**: Ghostty
- **Git tools**: git, gh, lazygit
- **File utilities**: zoxide, eza, bat, fd, ripgrep, fzf, tree
- **CLI**: jq, yq, starship, tmux
- **Nix tooling**: nixfmt-rfc-style, deadnix, statix

## Dotfiles

The Neovim configuration under `dotfiles/nvim/` is symlinked into `~/.config/nvim` via `xdg.configFile`. It uses the [LazyVim](https://www.lazyvim.org/) distribution with custom plugins (`relevo`, `termux`) and language snippets.

## Conventions

- Keep `home.stateVersion` in sync with the Home Manager release (`26.05`)
- Neovim is pinned via a separate `nixpkgs-neovim` input to avoid version drift
- Fish is the primary shell; bash is available as a fallback
- Ghostty is the default terminal emulator
- The devenv environment provides convenience scripts and git hooks for workflow automation

## Flake inputs

`home-manager` is not a direct input. It is reached through
[omniflake](https://omniflake.com/docs/using), a centralized index of Nix flakes:

```nix
inputs.omniflake.url = "github:fzakaria/omniflake";
inputs.omniflake.inputs.nixpkgs.follows = "nixpkgs";
...
home-manager = omniflake.flakes.home-manager;
```

The `follows` line makes our `nixpkgs` the one substituted into every indexed
flake, so `home-manager` evaluates against the same package set as everything else.

Two inputs stay direct:

- `nixpkgs` — it is the input omniflake substitutes; it has to be declared to be followed
- `nixpkgs-neovim` — an exact revision (`832efc09`), which the index cannot name

`nix flake update` now advances `home-manager` by advancing `omniflake`, whose
index carries the pin. The revision tracks omniflake's pinning cadence rather
than the tip of `master`.
