# Nix Home Manager Configuration

This is a Home Manager flake for macOS (aarch64-darwin), user "tianluo".
It declaratively manages the shell environment, editor tooling, CLI packages, and dotfiles.

## Key files
- `flake.nix` — Flake entry point; pins `nixpkgs` (nixos-unstable) and `nixpkgs-neovim` (commit 832efc09 → Neovim 0.11.2), and reaches `home-manager` through the `omniflake` index
- `home.nix` — The actual Home Manager module (programs, packages, dotfile symlinks)
- `devenv.nix` / `devenv.yaml` — devenv dev environment (git, jq, pi-coding-agent)
- `dotfiles/nvim/` — Neovim config, symlinked into `~/.config/nvim`

## Commands

Run `devenv shell` to enter the dev environment, then use:
- `apply` — apply home config (`home-manager switch --flake .#tianluo`)
- `update` — refresh pinned inputs (`nix flake update`)
- `check` — validate config without applying (`home-manager build --flake .#tianluo`)

## Conventions
- Target platform is `aarch64-darwin` (Apple Silicon macOS)
- Keep `home.stateVersion` in sync with the Home Manager release
- Third-party flakes come from [omniflake](https://omniflake.com/docs/using) as
  `omniflake.flakes.<name>`, not direct inputs. `omniflake.inputs.nixpkgs.follows = "nixpkgs"`
  makes every indexed flake evaluate against our `nixpkgs`
- `nixpkgs` and `nixpkgs-neovim` stay direct inputs: the first is the one omniflake
  substitutes into indexed flakes, the second is an exact revision the index cannot name
- `nix flake update` advances `home-manager` by advancing `omniflake`, whose index
  carries the pin — so the rev tracks omniflake's pinning cadence, not `master` tip
- Neovim is pinned via a separate `nixpkgs-neovim` input to avoid version drift
- Fish is the primary shell; bash is available as a fallback
- Ghostty is the default terminal emulator
