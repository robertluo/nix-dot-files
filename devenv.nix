{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.jq
    pkgs.pi-coding-agent
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
    nix build .#homeConfigurations.tianluo.homeConfigurations.tianluo
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    echo "Available scripts: apply, update, check"
  '';

  # See full reference at https://devenv.sh/reference/options/
}
