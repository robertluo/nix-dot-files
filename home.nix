{config, pkgs, pkgs-neovim, ...} :

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
    package = pkgs-neovim.neovim-unwrapped;
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
    loginShellInit = ''
     # Default system profile
     if test -d /nix/var/nix/profiles/default/bin
       fish_add_path --prepend --global /nix/var/nix/profiles/default/bin
     end

     # Per-user profile (standalone Nix or home-manager profile)
     if test -d /nix/var/nix/profiles/per-user/$USER/profile/bin
       fish_add_path --prepend --global /nix/var/nix/profiles/per-user/$USER/profile/bin
     end

     # Classic single-user symlink, if you still have it:
     if test -d ~/.nix-profile/bin
       fish_add_path --prepend --global ~/.nix-profile/bin
     end
     fish_add_path --global ~/.local/bin

     # Convenience aliases for home-manager
     alias hm-apply='home-manager switch --flake .#tianluo'
     alias hm-update='nix flake update'
     alias hm-check='nix build .#homeConfigurations.tianluo.homeConfigurations.tianluo'
     ''; 
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

    #support nix's own flake development
    pkgs.nixd
    pkgs.deadnix
    pkgs.statix
  ];

  xdg.configFile."nvim" = {
    source = ./dotfiles/nvim;
    recursive = true;
  };
}
