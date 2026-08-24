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
    home-manager switch --flake .#tianluo
  '';

  scripts.update.exec = ''
    nix flake update
  '';

  scripts.check.exec = ''
    home-manager build --flake .#tianluo
  '';

  scripts.update-readme.exec = ''
    pi -p "Update README.md to reflect the current state of this repository. Read flake.nix, home.nix, devenv.nix, devenv.yaml, and the dotfiles/ directory structure. Write the updated content to README.md." --no-session
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    echo "Available scripts: apply, update, check, update-readme"
  '';

  # See full reference at https://devenv.sh/reference/options/
}
