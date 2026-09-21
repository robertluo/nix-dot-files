# Nix Home Manager Configuration

This is a Home Manager flake for macOS (aarch64-darwin), user "tianluo".
It declaratively manages the shell environment, editor tooling, CLI packages, and dotfiles.

## Key files
- `flake.nix` — Flake entry point; pins `nixpkgs` (nixos-unstable), `nixpkgs-neovim` (commit 832efc09 → Neovim 0.11.6) and `nixpkgs-devenv` (commit aa88e342 → devenv 2.2.2), the latter two applied as overlays, reaches `home-manager` and `nix-doom-emacs-unstraightened` through the `omniflake` index, and takes `jolt` as a direct input surfaced through a third overlay
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
- `nixpkgs`, `nixpkgs-neovim`, `nixpkgs-devenv` and `jolt` stay direct inputs: the
  first is the one omniflake substitutes into indexed flakes, the next two are
  exact revisions the index cannot name, and the last is simply absent from the
  index
- `nix flake update` advances `home-manager` by advancing `omniflake`, whose index
  carries the pin — so the rev tracks omniflake's pinning cadence, not `master` tip
- Neovim is held on the 0.11 series by an overlay in `flake.nix` that takes
  `neovim-unwrapped` from `nixpkgs-neovim`; `home.nix` sets no `package` and takes
  no extra argument, so the pin lives entirely in the flake. nixpkgs has no
  versioned neovim attribute (no `neovim_0_11`), so a second nixpkgs is the only
  way onto a different series, and `nixos-25.11` — the sole named branch still on
  0.11 — stopped receiving commits 2026-06-30, hence the frozen revision
- devenv is held on 2.2.2 by the same mechanism — unstable's 2.3.1 carries a
  regression — an overlay in `flake.nix` takes `devenv` from `nixpkgs-devenv`,
  so `home.nix` keeps its plain `pkgs.devenv`. aa88e342 is the last master
  commit before nixpkgs bumped 2.2.2 -> 2.3.0, and its `devenv` closure is fully
  substitutable from cache.nixos.org on aarch64-darwin. To move the pin, find
  the commit that bumped past the wanted version
  (`gh api "repos/NixOS/nixpkgs/commits?path=pkgs/by-name/de/devenv/package.nix"`)
  and take its parent
- The CLI pin has a second half in `devenv.yaml`: the `devenv` input (the module
  set in `src/modules`) is unpinned by default and tracks the repo's main
  branch, so it drifts ahead of a held-back CLI. It is pinned to c972cb4, the
  commit that bumps `src/modules/latest-version` to 2.2.2. The matching `v2.2.2`
  tag is the wrong target: its `latest-version` still reads 2.2.1, and
  `update-check.nix` then nags on every shell entry that the CLI is newer than
  its input. The bump lands whenever the release automation next runs, not with
  the tag — for 2.2.2 that was 39 commits later, so the module set carries a few
  post-release fixes the 2.2.2 CLI never shipped with. Repin both halves together
- [Jolt](https://jolt-lang.net) (Clojure on Chez Scheme) is a direct input because
  the omniflake index does not carry it, and an overlay in `flake.nix` exposes its
  flake package so `home.nix` lists a plain `pkgs.jolt`. Two details are
  load-bearing, and both fail confusingly when missed:
  - the URL is `git+https://github.com/jolt-lang/jolt?submodules=1`, never
    `github:jolt-lang/jolt`. Jolt vendors its Scheme dependencies (irregex, sci,
    fs, process, grenadine) as git submodules, and the `github:` fetcher reads
    GitHub's tarball API, which omits them — the `vendor/` directories arrive
    empty and the build dies on a missing `vendor/irregex/irregex.scm`
  - `~/.config/nix/nix.conf` must enable the `flake-self-attrs` experimental
    feature, because Jolt's own flake sets `inputs.self.submodules`. Lix gates
    that attribute, and merely *locking* this input evaluates it, so the feature
    is a prerequisite for `apply` and `check` at all, not just for building Jolt
    directly. It is the one requirement here that lives outside the repo, so a
    fresh machine needs it set before the first `apply`
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
