# Nix Home Manager Configuration

Declarative macOS (Apple Silicon) environment managed via [Home Manager](https://github.com/nix-community/home-manager) and [devenv](https://devenv.sh/).

## Overview

| Component       | Version / Source                                                        |
|-----------------|-------------------------------------------------------------------------|
| nixpkgs         | `nixos-unstable` (direct input)                                         |
| home-manager    | via [omniflake](https://omniflake.com/docs/using) index                 |
| Neovim          | held on the 0.11 series by an overlay from `nixpkgs-neovim` (`832efc09`) |
| devenv          | held on 2.2.2 by an overlay from `nixpkgs-devenv` (`aa88e342`)           |
| Emacs           | stock `emacs` (NS/Cocoa) + Doom via `nix-doom-emacs-unstraightened`     |
| Target system   | `aarch64-darwin`                                                        |
| Shell           | Fish (bash available as a fallback)                                     |
| Terminal        | Ghostty                                                                 |

## Directory Structure

```
├── flake.nix          # Flake entry point; pins nixpkgs + omniflake, builds home config
├── home.nix           # Home Manager module (programs, packages, dotfile symlinks)
├── devenv.nix         # devenv dev environment (scripts, languages)
├── devenv.yaml        # devenv inputs (rolling nixpkgs, git-hooks.nix, modules pinned to 2.2.2)
└── dotfiles/
    ├── nvim/          # Neovim config (LazyVim-based), symlinked to ~/.config/nvim
    │   ├── init.lua   # Main entry point
    │   ├── lua/       # Custom plugins and community config
    │   ├── snippets/  # VSCode-style snippets (clojure, lua, markdown, global)
    │   └── ...
    └── doom/          # Doom Emacs DOOMDIR (init.el, config.el, packages.el)
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

Read `home.nix` — it is short and it is the source of truth. This file does not
restate the package list; a hand-kept copy only drifts.

## Dotfiles

The Neovim configuration under `dotfiles/nvim/` is symlinked into `~/.config/nvim` via `xdg.configFile`. It uses the [LazyVim](https://www.lazyvim.org/) distribution with custom plugins (`relevo`, `termux`) and language snippets.

## Emacs

Doom Emacs, built by
[nix-doom-emacs-unstraightened](https://github.com/marienz/nix-doom-emacs-unstraightened)
around nixpkgs' stock `emacs` (the NS/Cocoa build, so `Emacs.app` lands in
`~/Applications/Home Manager Apps`). `programs.doom-emacs` sets no `emacs`, so
the module's default applies — and staying on stock is what keeps this config
eligible for unstraightened's Cachix, which only holds the Doom package set
built against stock emacs. Nix resolves Doom's whole package set — there is no
`doom sync` step and no `~/.emacs.d` checkout.

The daemon runs as a launchd agent (`services.emacs`), never from a shell; see
AGENTS.md for why that distinction matters.

The config lives in `dotfiles/doom/`, and *when* a change takes effect depends
on which file you edit:

| File          | Read at | To apply     |
|---------------|---------|--------------|
| `init.el`     | build   | `apply`      |
| `packages.el` | build   | `apply`      |
| `config.el`   | startup | restart Emacs |

Because `doomDir` is a store path, new files must be `git add`ed before the
flake can see them.

## Conventions

- Keep `home.stateVersion` in sync with the Home Manager release (`26.05`)
- Neovim is held back by an overlay in `flake.nix` that takes `neovim-unwrapped`
  from `nixpkgs-neovim`; `home.nix` sets no package and knows nothing about the pin
- devenv is held on 2.2.2 the same way — 2.3.1 regressed — by an overlay taking
  `devenv` from `nixpkgs-devenv`; `home.nix` still just lists `pkgs.devenv`.
  `devenv.yaml` pins the matching module set, which otherwise tracks devenv's
  main branch and drifts ahead of the CLI
- Fish is the primary shell; bash is available as a fallback
- Ghostty is the default terminal emulator
- The devenv environment provides the convenience scripts above

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

Three inputs stay direct:

- `nixpkgs` — it is the input omniflake substitutes; it has to be declared to be followed
- `nixpkgs-neovim` — an exact revision (`832efc09`), which the index cannot name.
  nixpkgs carries no versioned neovim attribute, so a second nixpkgs is the only
  way onto a different series; it is consumed solely by the overlay in `flake.nix`
- `nixpkgs-devenv` — an exact revision (`aa88e342`), the last master commit before
  the `2.2.2 -> 2.3.0` bump; likewise consumed solely by an overlay

`nix flake update` now advances `home-manager` by advancing `omniflake`, whose
index carries the pin. The revision tracks omniflake's pinning cadence rather
than the tip of `master`.
