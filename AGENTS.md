# Nix Home Manager Configuration

This is a Home Manager flake for user "tianluo", shared by an Apple Silicon Mac
(`aarch64-darwin`) and headless NixOS machines (`x86_64-linux`, `aarch64-linux`).
It declaratively manages the shell environment, editor tooling, CLI packages, and dotfiles.

## Key files
- `flake.nix` — Flake entry point; pins `nixpkgs` (nixos-unstable), `nixpkgs-neovim` (commit 832efc09 → Neovim 0.11.6) and `nixpkgs-devenv` (commit aa88e342 → devenv 2.2.2), the latter two applied as overlays, reaches `home-manager` and `nix-doom-emacs-unstraightened` through the `omniflake` index, and takes `jolt` as a direct input surfaced through a third, conditionally applied overlay. `mkPkgs system` builds the package set and `mkHome { system, gui }` the configuration, so every machine shares one `home.nix`
- `home.nix` — The actual Home Manager module (programs, packages, dotfile symlinks); takes `gui` as a module argument
- `devenv.nix` / `devenv.yaml` — devenv dev environment (git, jq, pi-coding-agent)
- `dotfiles/nvim/` — Neovim config, symlinked into `~/.config/nvim`

## Commands

Run `devenv shell` to enter the dev environment, then use:
- `apply` — apply home config (`home-manager switch --flake ".#$(whoami)@$(nix eval --impure --raw --expr builtins.currentSystem)"`)
- `update` — refresh pinned inputs (`nix flake update`)
- `check` — validate config without applying (same attribute as `apply`, with `home-manager build`)

The scripts derive the attribute from `whoami` and `builtins.currentSystem` rather than
hardcoding one, so the same command is correct on every machine. Hardcoding
`.#tianluo` would silently build the *Darwin* configuration on a Linux box.

## Conventions
- Configurations are the cross product of two lists in `flake.nix`:
  `usernames = [ "tianluo" "admin" ]` and
  `systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ]`, built with
  `lib.cartesianProduct` into `"<user>@<system>"` attributes, plus a bare
  `tianluo` for the Mac (that is what `home-manager switch --flake .` falls back
  to when no `<user>@<hostname>` attribute matches). `apply` resolves
  `<whoami>@<currentSystem>`, so a new machine needs no flake change as long as
  its pair is already listed. Adding a user is one word in `usernames`
- `pkgsBySystem = lib.genAttrs systems mkPkgs` gives one package set per system,
  imported at most once however many users share it. `genAttrs` is lazy, so
  systems nobody evaluates cost nothing
- Two independent axes, deliberately not conflated:
  - `gui`, passed through `extraSpecialArgs` — desktop vs headless. `gui = false`
    drops Ghostty and neovide and swaps Doom's Emacs for `emacs-nox`
  - `pkgs.stdenv.hostPlatform.isDarwin`, read inside `home.nix` — macOS vs Linux.
    It picks the home directory, chooses `ghostty-bin` over the source build, and
    gates the launchd block
  Which machines get a GUI is selected centrally by `guiFor` in `flake.nix`
  (today: `system == "aarch64-darwin"`), but `home.nix` still reads the two as
  separate axes, so a Linux desktop is a change to `guiFor` alone. Keep new
  conditionals on whichever axis actually applies
- `username` reaches `home.nix` through `extraSpecialArgs` alongside `gui`, and
  `home.username` and `home.homeDirectory` are both derived from it — the latter
  by prefixing `/Users/` or `/home/`, since standalone Home Manager gives
  `homeDirectory` no platform-derived default (it is undefined for
  `stateVersion >= 20.09`). Home Manager's activation script hard-fails on a
  mismatch (`checkStringEq USER "$USER" <home.username>` in
  `modules/home-environment.nix`), so an attribute built for the wrong user
  aborts rather than writing to someone else's home
- Platform differences live in `home.nix` behind those two guards, not in
  per-machine modules. The file is small enough that one copy with guards beats
  three files to keep in sync
- `home.packages` is one flat, order-preserving list filtered with
  `lib.filter (p: p != null)`, with conditional entries written inline as
  `(pkgs.jolt or null)` and `(if gui then pkgs.neovide else null)`. Appending
  conditionals with `++ lib.optional` instead would reorder the list and churn
  the profile hash on every machine for no behavioural change
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
  substitutable from cache.nixos.org on aarch64-darwin and aarch64-linux
  (checked 2026-09-22 by querying the narinfo for the resolved output path;
  the neovim pin, emacs-nox, jujutsu and babashka are cached there too), so
  the pins cost nothing on a Linux box. To move the pin, find
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
 Launchd agents do not source `hm-session-vars.sh`, so
  `launchd.agents.emacs.config.EnvironmentVariables` hands the daemon
  `home.sessionVariables` plus `TERMINFO_DIRS`. Without the latter a tty frame
  in Ghostty dies on "Terminal type xterm-ghostty is not defined" — the entry
  lives in the profile's `share/terminfo`, off the compiled-in ncurses path, and
  the client's own environment does not help because the lookup happens in the
  daemon. The block is `lib.mkIf isDarwin` and has no Linux counterpart on
  purpose: Home Manager's systemd user unit runs `ExecStart` through a login
  shell (`$SHELL -l -c`), which sources the session variables already. Setting
  `launchd.agents.*` on Linux would be inert rather than an error —
  `launchd.enable` defaults to `isDarwin` — but the guard says why
- On NixOS the machine's own `configuration.nix` must carry
  `programs.fish.enable = true` and `users.users.tianluo.shell = pkgs.fish`;
  standalone Home Manager cannot register a login shell in `/etc/shells`.
  Headless boxes also need `loginctl enable-linger tianluo`, or the Emacs daemon
  exits with the SSH session that started it
- Fish is the primary shell; bash is available as a fallback
- Ghostty is the default terminal emulator on the GUI profile; `ghostty-bin` is
  the prebuilt macOS app and is `aarch64-darwin` only, so `home.nix` selects the
  source build off Darwin
