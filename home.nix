{config, pkgs, ...} :

{
  home.username = "tianluo";
  home.homeDirectory = "/Users/tianluo";
  home.stateVersion = "26.05";

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
     devenv hook fish | source
     ''; 
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
    pkgs.ghostty-bin
    pkgs.curl
  ];

  xdg.configFile."nvim" = {
    source = ./dotfiles/nvim;
    recursive = true;
  };
}
