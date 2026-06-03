{config, pkgs, ...} :

{
  home.username = "tianluo";
  home.homeDirectory = "/Users/tianluo";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "z" ];
      theme = "robbyrussell";
    };
  };

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

  home.packages = [
    pkgs.git
    pkgs.jujutsu
    pkgs.bashInteractive
  ];

  xdg.configFile."nvim" = {
    source = ./dotfiles/nvim;
    recursive = true;
  };
}
