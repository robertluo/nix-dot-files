{pkgs, ...} :

{
  home.username = "tianluo";
  home.homeDirectory = "/Users/tianluo";
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
    # emacs-mac(port) — the macOS-native build, wrapped with Doom by
    # nix-doom-emacs-unstraightened (module wired in flake.nix)
    emacs = pkgs.emacs-macport;
    doomDir = ./dotfiles/doom;
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

  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    settings = {
      font-size = 14;
      background-opacity = 0.95;
    };
  };

  home.packages = [
    pkgs.git
    pkgs.jujutsu
    pkgs.bashInteractive
    pkgs.ripgrep
    pkgs.babashka
    pkgs.devenv
    pkgs.mosh
    pkgs.github-cli
    pkgs.neovide
    pkgs.curl
    pkgs.doctl

    pkgs.pi-coding-agent
  ];

  xdg.configFile."nvim" = {
    source = ./dotfiles/nvim;
    recursive = true;
  };
}
