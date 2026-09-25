# Nix Home Manager Configuration

Declarative environment managed via [Home Manager](https://github.com/nix-community/home-manager)
and [devenv](https://devenv.sh/), shared by a macOS workstation and headless
NixOS machines.

## Overview

| Component       | Version / Source                                                        |
|-----------------|-------------------------------------------------------------------------|
| nixpkgs         | `nixos-unstable` (direct input)                                         |
| home-manager    | via [omniflake](https://omniflake.com/docs/using) index                 |
| Neovim          | held on the 0.11 series by an overlay from `nixpkgs-neovim` (`832efc09`) |
| devenv          | held on 2.2.2 by an overlay from `nixpkgs-devenv` (`aa88e342`)           |
| Target systems  | `aarch64-darwin` (GUI), `x86_64-linux` / `aarch64-linux` (headless)     |
| Shell           | Fish (bash available as a fallback)                                     |
| Terminal        | Ghostty (GUI profile only)                                              |

## Systems and profiles

`flake.nix` builds every configuration through one `mkHome { system, username }`,
so `home.nix` is shared verbatim and varies along two independent axes:

- **`gui`**, passed in via `extraSpecialArgs` — the desktop/headless split.
  `gui = false` drops Ghostty and neovide and swaps Doom's Emacs for `emacs-nox`
- **`pkgs.stdenv.hostPlatform.isDarwin`**, read inside `home.nix` — the
  macOS/Linux split. It picks the home directory, chooses `ghostty-bin` over the
  source build, and gates the launchd block

Keeping the two apart means a Linux desktop would only need `gui = true`; nothing
in `home.nix` conflates "has a screen" with "is a Mac". Which machines get a GUI
is decided in one place, `guiFor` in `flake.nix`, currently "the Mac and nothing
else".

Neither the user nor the system is baked into `home.nix`. Both are lists in
`flake.nix`, and the configurations are their cross product:

```nix
usernames = [ "tianluo" "admin" ];
systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
```

which yields `tianluo@aarch64-darwin`, `admin@x86_64-linux`, and so on — plus a
bare `tianluo` for the Mac, since that is where `home-manager switch --flake .`
lands when no `<user>@<hostname>` attribute matches. `home.username` and
`home.homeDirectory` are derived from whichever name the attribute carries, so
`admin` gets `/home/admin` without a second copy of anything.

`apply` resolves `<whoami>@<currentSystem>`, so **a new machine needs no change
here at all** as long as its user and system already appear in those two lists.
Adding a user is one word.

### NixOS prerequisites

Home Manager is used standalone here, so a few settings stay in the machine's own
`configuration.nix`:

```nix
programs.fish.enable = true;          # registers fish in /etc/shells
users.users.tianluo.shell = pkgs.fish;
nix.settings.experimental-features = [ "nix-command" "flakes" "flake-self-attrs" ];
```

Home Manager cannot register a login shell itself. On a headless box also run
`loginctl enable-linger tianluo`, or the Emacs daemon dies with the SSH session
that started it.

## Directory Structure

```
├── flake.nix          # Flake entry point; pins nixpkgs + omniflake + jolt, builds home configs
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
```

`apply` and `check` resolve the attribute from `whoami` and `builtins.currentSystem`, so the
same command targets the right configuration on every machine.

## Programs & Tools

Read `home.nix` — it is short and it is the source of truth. This file does not
restate the package list; a hand-kept copy only drifts.

## Dotfiles

The Neovim configuration under `dotfiles/nvim/` is symlinked into `~/.config/nvim` via `xdg.configFile`. It uses the [LazyVim](https://www.lazyvim.org/) distribution with custom plugins (`relevo`, `termux`) and language snippets.

## Conventions

- Keep `home.stateVersion` in sync with the Home Manager release (`26.05`)
- Platform differences live in `home.nix` behind `isDarwin` or the `gui`
  argument, never in a separate per-machine module; the file is small enough
  that one copy with two guards beats three files to keep in sync
- Neovim is held back by an overlay in `flake.nix` that takes `neovim-unwrapped`
  from `nixpkgs-neovim`; `home.nix` sets no package and knows nothing about the pin
- devenv is held on 2.2.2 the same way — 2.3.1 regressed — by an overlay taking
  `devenv` from `nixpkgs-devenv`; `home.nix` still just lists `pkgs.devenv`.
  `devenv.yaml` pins the matching module set, which otherwise tracks devenv's
  main branch and drifts ahead of the CLI
- Fish is the primary shell; bash is available as a fallback
- Ghostty is the default terminal emulator on the GUI profile
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

Four inputs stay direct:

- `nixpkgs` — it is the input omniflake substitutes; it has to be declared to be followed
- `nixpkgs-neovim` — an exact revision (`832efc09`), which the index cannot name.
  nixpkgs carries no versioned neovim attribute, so a second nixpkgs is the only
  way onto a different series; it is consumed solely by the overlay in `flake.nix`
- `nixpkgs-devenv` — an exact revision (`aa88e342`), the last master commit before
  the `2.2.2 -> 2.3.0` bump; likewise consumed solely by an overlay
- `jolt` — the omniflake index does not carry it, so there is nothing to reach
  through. Like the two pins above it is consumed only by an overlay, which
  surfaces its flake package as `pkgs.jolt` — but that overlay is applied only
  where `jolt.packages` has an entry for the system. Jolt ships
  `aarch64-darwin` and `x86_64-linux`, so on `aarch64-linux` the overlay is
  skipped, `pkgs.jolt` does not exist, and the `(pkgs.jolt or null)` entry in
  `home.nix` filters itself out rather than failing to evaluate

`nix flake update` now advances `home-manager` by advancing `omniflake`, whose
index carries the pin. The revision tracks omniflake's pinning cadence rather
than the tip of `master`.

