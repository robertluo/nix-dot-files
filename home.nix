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
    pkgs.devenv
    pkgs.mosh
    pkgs.github-cli
    (if gui then pkgs.neovide else null)
    pkgs.curl
    pkgs.tmux
  ];

  xdg.configFile."nvim" = {
    source = ./dotfiles/nvim;
    recursive = true;
  };
}
