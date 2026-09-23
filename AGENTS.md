# Nix Home Manager Configuration

This is a Home Manager flake for user "tianluo", shared by an Apple Silicon Mac
(`aarch64-darwin`) and headless NixOS machines (`x86_64-linux`, `aarch64-linux`).
It declaratively manages the shell environment, editor tooling, CLI packages, and dotfiles.

## Key files
- `flake.nix` — Flake entry point; pins `nixpkgs` (nixos-unstable), `nixpkgs-neovim` (commit 832efc09 → Neovim 0.11.6) and `nixpkgs-devenv` (commit aa88e342 → devenv 2.2.2), the latter two applied as overlays, reaches `home-manager` and `nix-doom-emacs-unstraightened` through the `omniflake` index, and takes `jolt` as a direct input surfaced through a third, conditionally applied overlay. `mkPkgs system` builds the package set and `mkHome { system, gui }` the configuration, so every machine shares one `home.nix`
- `home.nix` — The actual Home Manager module (programs, packages, dotfile symlinks); takes `gui` as a module argument
- `devenv.nix` / `devenv.yaml` — devenv dev environment (git, jq, pi-coding-agent)
- `dotfiles/nvim/` — Neovim config, symlinked into `~/.config/nvim`
- `dotfiles/doom/` — Doom Emacs config (DOOMDIR), baked into the store by the build

## Commands

Run `devenv shell` to enter the dev environment, then use:
- `apply` — apply home config (`home-manager switch --flake ".#$(whoami)@$(nix eval --impure --raw --expr builtins.currentSystem)"`)
- `update` — refresh pinned inputs (`nix flake update`)
- `check` — validate config without applying (same attribute as `apply`, with `home-manager build`)

The scripts derive the attribute from `whoami` and `builtins.currentSystem` rather than
hardcoding one, so the same command is correct on every machine. Hardcoding
`.#tianluo` would silently build the *Darwin* configuration on a Linux box.

## Conventions
- Four `homeConfigurations` attributes: `tianluo` and `tianluo@aarch64-darwin`
  (the same GUI config under both names), `tianluo@x86_64-linux` and
  `tianluo@aarch64-linux` (headless). Every machine answers to `<user>@<system>`;
  the Mac keeps the bare name too, because that is what
  `home-manager switch --flake .` falls back to when no `<user>@<hostname>`
  attribute matches
- Two independent axes, deliberately not conflated:
  - `gui`, passed through `extraSpecialArgs` — desktop vs headless. `gui = false`
    drops Ghostty and neovide and swaps Doom's Emacs for `emacs-nox`
  - `pkgs.stdenv.hostPlatform.isDarwin`, read inside `home.nix` — macOS vs Linux.
    It picks the home directory, chooses `ghostty-bin` over the source build, and
    gates the launchd block
  A Linux desktop would therefore be `gui = true` and nothing else. Keep new
  conditionals on whichever axis actually applies
- `username` is defined once, in `flake.nix`, and reaches `home.nix` through
  `extraSpecialArgs` alongside `gui`. `home.username` and `home.homeDirectory`
  are both derived from it — the latter by prefixing `/Users/` or `/home/`,
  since standalone Home Manager gives `homeDirectory` no platform-derived
  default (it is undefined for `stateVersion >= 20.09`). Before this the flake's
  `username` only named the attributes while `home.nix` carried its own literal,
  so changing one moved the attribute name and left the config building for the
  old user
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
- [Jolt](https://jolt-lang.net) (Clojure on Chez Scheme) is a direct input because
  the omniflake index does not carry it, and an overlay in `flake.nix` exposes its
  flake package so `home.nix` lists a plain `pkgs.jolt`. Three details are
  load-bearing, and the first two fail confusingly when missed:
  - the URL is `git+https://github.com/jolt-lang/jolt?submodules=1`, never
    `github:jolt-lang/jolt`. Jolt vendors its Scheme dependencies (irregex, sci,
    fs, process, grenadine) as git submodules, and the `github:` fetcher reads
    GitHub's tarball API, which omits them — the `vendor/` directories arrive
    empty and the build dies on a missing `vendor/irregex/irregex.scm`
  - the `flake-self-attrs` experimental feature must be enabled —
    `~/.config/nix/nix.conf` on macOS, `nix.settings.experimental-features` on
    NixOS — because Jolt's own flake sets `inputs.self.submodules`. Lix gates
    that attribute, and merely *locking* this input evaluates it, so the feature
    is a prerequisite for `apply` and `check` at all, not just for building Jolt
    directly. It is the one requirement here that lives outside the repo, so a
    fresh machine needs it set before the first `apply`. Stock Nix treats an
    unknown feature name as a warning, not an error, so setting it is safe there
  - Jolt publishes only `aarch64-darwin` and `x86_64-linux`. The overlay is
    therefore wrapped in `lib.optional (jolt.packages ? ${system})`, and on
    `aarch64-linux` it is skipped entirely — `pkgs.jolt` does not exist there, and
    `(pkgs.jolt or null)` in `home.nix` filters itself out instead of failing to
    evaluate. Adding a system to Jolt upstream needs no change here
- Emacs is wrapped with Doom by
  [nix-doom-emacs-unstraightened](https://github.com/marienz/nix-doom-emacs-unstraightened),
  reached through the omniflake index; its `homeModule` is added to the module
  list in `flake.nix`. On the GUI profile `programs.doom-emacs.emacs` is nixpkgs'
  stock `emacs` (the NS/Cocoa build), which is also the module's own default.
  Unstraightened's Cachix only holds the Doom package set built against stock
  emacs, so staying on stock keeps that configuration eligible for it — but that
  cache is not a substituter here, so `apply` still builds the package set
  locally. Headless machines pass `emacs-nox`, dropping the GTK/X closure for a
  daemon nothing can open a graphical frame against; the same reasoning says the
  forfeited Cachix eligibility costs nothing in practice
- `nix-doom-emacs-unstraightened` uses IFD — it builds a `doom-intermediates`
  derivation during evaluation — so the Linux configurations cannot be fully
  evaluated from the Mac without a Linux builder. `nix eval` there fails with
  "a 'x86_64-linux' ... is required to build". To check the rest of a Linux
  config from macOS, stub the module out:
  `hc.extendModules { modules = [ { programs.doom-emacs.enable = lib.mkForce false; } ]; }`
- The Emacs daemon is a service (`services.emacs`), never started from a shell.
  Emacs derives its socket dir as `${TMPDIR:-/tmp}/emacs$UID`, and client
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
- Doom's package set is resolved by Nix, never by `doom sync`. `dotfiles/doom/init.el`
  and `packages.el` are read at *build* time — changing them means `apply`.
  `config.el` is read at startup, so it only needs an Emacs restart
- Fish is the primary shell; bash is available as a fallback
- Ghostty is the default terminal emulator on the GUI profile; `ghostty-bin` is
  the prebuilt macOS app and is `aarch64-darwin` only, so `home.nix` selects the
  source build off Darwin
