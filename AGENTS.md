# Nix Home Manager Configuration

This is a Home Manager flake for macOS (aarch64-darwin), user "tianluo".
It declaratively manages the shell environment, editor tooling, CLI packages, and dotfiles.

## Key files
- `flake.nix` — Flake entry point; pins `nixpkgs` (nixos-26.05), `home-manager` (release-26.05), and `nixpkgs-neovim` (commit 832efc09 → Neovim 0.11.2)
- `home.nix` — The actual Home Manager module (programs, packages, dotfile symlinks)
- `devenv.nix` / `devenv.yaml` — devenv dev environment (git, jq, pi-coding-agent)
- `dotfiles/nvim/` — Neovim config, symlinked into `~/.config/nvim`

## Commands
- Activate: `home-manager switch --flake ~/.nix#tianluo`
- Update inputs: `nix flake update`

## Conventions
- Target platform is `aarch64-darwin` (Apple Silicon macOS)
- Keep `home.stateVersion` in sync with the Home Manager release
- Neovim is pinned via a separate `nixpkgs-neovim` input to avoid version drift
- Fish is the primary shell; bash is available as a fallback
- Ghostty is the default terminal emulator
