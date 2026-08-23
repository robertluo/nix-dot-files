# ~/.nix — Home Manager Configuration

This repository contains my [Home Manager](https://github.com/nix-community/home-manager)
configuration for a **macOS (aarch64-darwin)** machine, managed as a Nix flake.

It sets up my shell environment, editor tooling, common CLI packages, a
devenv development environment, and managed dotfiles for Neovim.

## Structure

```
~/.nix
├── flake.nix            # Flake entry point: pins inputs & defines the home configuration
├── flake.lock           # Locked versions of all inputs (auto-generated)
├── home.nix             # The actual Home Manager module (programs, packages, dotfiles)
├── dotfiles/
│   └── nvim/            # Neovim configuration, symlinked into ~/.config/nvim
├── devenv.nix           # devenv development environment (git, jq, pi-coding-agent)
├── devenv.yaml          # devenv input configuration
├── devenv.lock          # Locked devenv inputs (auto-generated)
└── .gitignore           # Ignores devenv/direnv/pre-commit local artifacts
```

## What it does

- **Shells**
  - `fish` — enabled with login shell init that sets up Nix profile paths and sources `devenv`.
  - `bash` — enabled as an interactive shell.
  - `man` — enabled with `man-db` as the man page viewer.

- **Terminal**
  - `ghostty` — enabled as the default terminal emulator (`ghostty-bin`),
    configured with font size 14 and 95% background opacity.

- **Editor**
  - `neovim` — enabled as the default editor (`viAlias`, `vimAlias`, `vimdiffAlias`),
    using a pinned `neovim-unwrapped` package from the `nixpkgs-neovim` input.
  - Neovim dotfiles from `dotfiles/nvim` are symlinked into `~/.config/nvim` (recursive).

- **Packages** (`home.packages`)
  - `git`, `jujutsu` (jj), `bashInteractive`, `ripgrep`, `babashka`, `devenv`,
    `mosh`, `github-cli`, `neovide`, `curl`, `doctl`
  - Nix flake tooling: `nixd`, `statix`, `deadnix`

- **Devenv** — a development environment providing `git`, `jq`, and `pi-coding-agent`.

## Inputs (pinned in `flake.nix`)

| Input | Source |
| --- | --- |
| `nixpkgs` | `github:NixOS/nixpkgs/nixos-26.05` |
| `nixpkgs-neovim` | pinned commit `832efc09...` (Neovim 0.11.2) |
| `home-manager` | `github:nix-community/home-manager/release-26.05` |

`home-manager`'s `nixpkgs` follows the main `nixpkgs` input.

## Usage

Build the home configuration for user `tianluo`:

```sh
nix build .#homeConfigurations.tianluo.homeConfigurations.tianluo
```

Or activate directly with Home Manager:

```sh
home-manager switch --flake ~/.nix#tianluo
```

> The flake targets `aarch64-darwin` (Apple Silicon macOS) and user `tianluo`.

## Updating

```sh
nix flake update   # refresh flake.lock to latest allowed versions
```

## Recent changes

- Removed `emacs` / Spacemacs from the configuration
- Added `doctl` (DigitalOcean CLI)
- Pinned Neovim to 0.11.6 and disabled spellcheck
- Configured Ghostty and added `curl`
- Added `neovide` (Neovim GUI)

## Notes

- `home.stateVersion = "26.05"` — keep this in sync with your Home Manager release.
- `home.username = "tianluo"`, `home.homeDirectory = "/Users/tianluo"`.
- The `.gitignore` excludes devenv/direnv/pre-commit local files (e.g. `.devenv*`, `.direnv`).