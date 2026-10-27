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
    pkgs.mosh
    pkgs.github-cli
    pkgs.doctl
    pkgs.claude-code
    (if gui then pkgs.neovide else null)
    pkgs.curl
  ];

  xdg.configFile."nvim" = {
    source = ./dotfiles/nvim;
    recursive = true;
  };
}
