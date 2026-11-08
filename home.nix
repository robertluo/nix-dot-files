{config, lib, pkgs, gui, username, ...} :

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  home.username = username;
  home.homeDirectory = (if isDarwin then "/Users/" else "/home/") + username;
  home.stateVersion = "26.05";

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LANGUAGE = "en_US:en";
    LC_MESSAGES = "en_US.UTF-8";
  };

  # oMLX (Apple Silicon only) installs its CLI shims here and, left to itself,
  # appends a PATH block to ~/.zshrc, which replaces the managed symlink and
  # blocks the next switch. Declaring the path covers every shell instead.
  home.sessionPath = lib.mkIf isDarwin [ "$HOME/.omlx/bin" ];

  programs.home-manager.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

  programs.bash = {
    enable = true;
  };

  programs.man = {
    enable = true;
    package = pkgs.man-db;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
      ];
    };
  };

  programs.devenv = {
    enable = true;
    enableZshIntegration = true;
 };

  # devenv's hook spawns a nested `devenv shell`; cd-ing out makes that shell
  # exit and the parent follow into the new directory, but the parent's precmd
  # has already run, so a direct project->project cd is not activated until the
  # next prompt (cachix/devenv#3129). Re-run the hook until PWD settles.
  # mkAfter: must follow the integration's `eval "$(devenv hook zsh)"`.
  programs.zsh.initContent = lib.mkAfter ''
    if (( $+functions[_devenv_hook] )); then
      functions[_devenv_hook_once]=$functions[_devenv_hook]
      _devenv_hook_status() { return $1 }
      _devenv_hook() {
        local st=$? before
        while :; do
          before=$PWD
          _devenv_hook_status $st
          _devenv_hook_once
          [[ $PWD == $before ]] && break
        done
        return $st
      }
    fi
  '';

  programs.zellij = {
    enable = true;
  };

  programs.ghostty = lib.mkIf gui {
    enable = true;
    # ghostty-bin is the prebuilt macOS app and is aarch64-darwin only;
    # elsewhere the source build is the native one anyway.
    package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    settings = {
      font-size = 14;
      background-opacity = 0.95;
    };
  };

  home.packages = lib.filter (p: p != null) [
    pkgs.git
    pkgs.jujutsu
    pkgs.bashInteractive
    pkgs.ripgrep
    pkgs.tree-sitter
    pkgs.babashka
    (pkgs.jolt or null)
    pkgs.mosh
    pkgs.github-cli
    pkgs.doctl
    pkgs.tuios
    pkgs.claude-code
    pkgs.curl
  ];

  # Panes inherit the tuios daemon's environment, and the daemon is otherwise
  # spawned by whichever shell first runs `tuios`. Started from inside a devenv
  # shell, every pane carries that DEVENV_ROOT and devenv's hook, which treats
  # it as "already active", never switches projects. launchd starts it clean.
  # KeepAlive also restarts it after `tuios kill-server`, so a stray shell
  # never gets the chance to spawn one; while another daemon holds the socket
  # it exits 1 and the service manager retries every 10s.
  #
  # The binary is reached through the profile, not a store path: a store path
  # would change the unit on every tuios bump, and the switch would restart
  # the daemon, closing every pane, including the one running `apply`. After
  # an upgrade, `tuios kill-server` to move the daemon onto the new binary.
  launchd.agents.tuios = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${config.home.profileDirectory}/bin/tuios" "daemon" ];
      WorkingDirectory = config.home.homeDirectory;
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/tuios-daemon.log";
    };
  };

  # Linux counterpart. Headless boxes need `loginctl enable-linger`, or the
  # user manager, and every pane with it, goes away with the last SSH session.
  systemd.user.services.tuios = lib.mkIf (!isDarwin) {
    Unit = {
      Description = "tuios daemon";
      # Same reason as the profile path: never restart it from a switch.
      X-RestartIfChanged = false;
    };
    Service = {
      ExecStart = "${config.home.profileDirectory}/bin/tuios daemon";
      WorkingDirectory = config.home.homeDirectory;
      Restart = "always";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # tuios merges every config.d/*.toml under config.toml, which wins over
  # them. Nix owns this drop-in; config.toml stays writable, so the settings
  # page and `tuios set-config` keep working (and override anything here).
  # The directory is adrg/xdg's config home: ~/Library/Application Support
  # on macOS, $XDG_CONFIG_HOME elsewhere.
  #
  # The Claude Code status line feed (`tuios integration install claude-code
  # --statusline`, written into the mutable ~/.claude/settings.json) puts
  # model, context and cost in each agent pane's metadata. The shipped rail
  # row hides model and cost, and shows context only from 80% as "ctx 84%".
  # $model, $context and $cost draw the raw values on every row instead,
  # replacing the `context` token so a full window is not listed twice.
  #
  # $context arrives as a whole percent ("42%"), which the rules' gt/lt cannot
  # read as a number, so the colouring is by text, first match wins: 8% and
  # 9% are caught before the "8"/"9" prefixes that mark 80-99%.
  home.file."${if isDarwin then "${config.home.homeDirectory}/Library/Application Support" else config.xdg.configHome}/tuios/config.d/nix.toml".source =
    (pkgs.formats.toml { }).generate "tuios-nix.toml" {
      appearance.sidebar = {
        # The note line drops its last token first; at 24 columns the three
        # values leave no room for `now`.
        width = 32;
        agent_row = {
          tokens = [
            "session" "need" "harness" "name" "progress" "elapsed"
            "$context" "$cost" "$model"
            "subagents" "pr" "meta" "now" "message"
          ];
          "$context" = {
            fg = "muted";
            rule = [
              { equals = "8%"; fg = "muted"; }
              { equals = "9%"; fg = "muted"; }
              { equals = "100%"; fg = "error"; bold = true; }
              { starts_with = "9"; fg = "error"; }
              { starts_with = "8"; fg = "warning"; }
            ];
          };
          "$cost".fg = "muted";
          "$model".fg = "muted";
        };
      };
    };

  xdg.configFile."nvim" = {
    source = ./dotfiles/nvim;
    recursive = true;
  };
}
