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

  programs.home-manager.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

  programs.doom-emacs = {
    enable = true;
    doomDir = ./dotfiles/doom;
    # the module defaults to pkgs.emacs, which drags in GTK and X. Headless
    # machines only ever reach the daemon over a terminal or emacsclient.
    emacs = if gui then pkgs.emacs else pkgs.emacs-nox;
  };

  services.emacs.enable = true;

  # launchd starts agents with a bare environment, so the daemon needs the
  # session variables spelled out. The systemd user service home-manager
  # generates on Linux runs ExecStart through a login shell, which already
  # picks them up.
  launchd.agents.emacs.config.EnvironmentVariables = lib.mkIf isDarwin (
    config.home.sessionVariables // {
      TERMINFO_DIRS = "${config.home.profileDirectory}/share/terminfo:/usr/share/terminfo";
    }
  );

  programs.bash = {
    enable = true;
  };

  programs.man = {
    enable = true;
    package = pkgs.man-db;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = "devenv hook fish | source";
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
    pkgs.babashka
    # jolt builds only for aarch64-darwin and x86_64-linux; elsewhere the
    # overlay in flake.nix is skipped and pkgs.jolt does not exist
    (pkgs.jolt or null)
    pkgs.devenv
    pkgs.mosh
    pkgs.github-cli
    (if gui then pkgs.neovide else null)
    pkgs.curl
    pkgs.doctl
    pkgs.tmux
  ];

  xdg.configFile."nvim" = {
    source = ./dotfiles/nvim;
    recursive = true;
  };
}
