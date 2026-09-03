# Nix Home Manager Configuration

This is a Home Manager flake for macOS (aarch64-darwin), user "tianluo".
It declaratively manages the shell environment, editor tooling, CLI packages, and dotfiles.

## Key files
- `flake.nix` — Flake entry point; pins `nixpkgs` (nixos-unstable) and `nixpkgs-neovim` (commit 832efc09 → Neovim 0.11.6) applied as an overlay, and reaches `home-manager` and `nix-doom-emacs-unstraightened` through the `omniflake` index
- `home.nix` — The actual Home Manager module (programs, packages, dotfile symlinks)
- `devenv.nix` / `devenv.yaml` — devenv dev environment (git, jq, pi-coding-agent)
- `dotfiles/nvim/` — Neovim config, symlinked into `~/.config/nvim`
- `dotfiles/doom/` — Doom Emacs config (DOOMDIR), baked into the store by the build

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
- Neovim is held on the 0.11 series by an overlay in `flake.nix` that takes
  `neovim-unwrapped` from `nixpkgs-neovim`; `home.nix` sets no `package` and takes
  no extra argument, so the pin lives entirely in the flake. nixpkgs has no
  versioned neovim attribute (no `neovim_0_11`), so a second nixpkgs is the only
  way onto a different series, and `nixos-25.11` — the sole named branch still on
  0.11 — stopped receiving commits 2026-06-30, hence the frozen revision
- Emacs is nixpkgs' stock `emacs` (the NS/Cocoa build) wrapped with Doom by
  [nix-doom-emacs-unstraightened](https://github.com/marienz/nix-doom-emacs-unstraightened),
  reached through the omniflake index; its `homeModule` is added to the module
  list in `flake.nix`, and `programs.doom-emacs` sets no `emacs` in `home.nix`,
  so the module's default applies. Unstraightened's Cachix only holds the Doom
  package set built against stock emacs, so staying on stock keeps this config
  eligible for it — but that cache is not a substituter here, so `apply` still
  builds the package set locally
- The Emacs daemon is a launchd agent (`services.emacs`), never started from a
  shell. Emacs derives its socket dir as `${TMPDIR:-/tmp}/emacs$UID`, and client
  and server each compute it from their own environment: started from the
  devShell, which carries no `TMPDIR`, the daemon listened on `/tmp/emacs502`
  while `emacsclient` — seeing macOS's per-user `/var/folders/…/T` — looked
  elsewhere and reported "can't find socket". launchd agents run in the per-user
  domain and get that same `TMPDIR`, so bare `emacsclient -t` finds them.
  `programs.doom-emacs` wires `services.emacs.package` to the Doom-wrapped Emacs
  on its own, given `provideEmacs` (default true)
- Launchd agents do not source `hm-session-vars.sh`, so
  `launchd.agents.emacs.config.EnvironmentVariables` hands the daemon
  `home.sessionVariables` plus `TERMINFO_DIRS`. Without the latter a tty frame
  in Ghostty dies on "Terminal type xterm-ghostty is not defined" — the entry
  lives in the profile's `share/terminfo`, off the compiled-in ncurses path, and
  the client's own environment does not help because the lookup happens in the
  daemon
- Doom's package set is resolved by Nix, never by `doom sync`. `dotfiles/doom/init.el`
  and `packages.el` are read at *build* time — changing them means `apply`.
  `config.el` is read at startup, so it only needs an Emacs restart
- Fish is the primary shell; bash is available as a fallback
- Ghostty is the default terminal emulator
