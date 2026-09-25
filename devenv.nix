{ pkgs, ... }:

{
  packages = [
    pkgs.jq
    #support nix's own flake development
    pkgs.nixd
    pkgs.deadnix
    pkgs.statix
  ];

  # https://devenv.sh/languages/
  languages.nix.enable = true;

  # https://devenv.sh/scripts/
  scripts.apply.exec = ''
    home-manager switch --flake ".#$(whoami)@$(nix eval --impure --raw --expr builtins.currentSystem)"
  '';

  scripts.update.exec = ''
    nix flake update
  '';

  scripts.check.exec = ''
    home-manager build --flake ".#$(whoami)@$(nix eval --impure --raw --expr builtins.currentSystem)"
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    echo "Available scripts: apply, update, check, update-readme"
  '';

  # See full reference at https://devenv.sh/reference/options/
}
