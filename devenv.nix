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

  # See full reference at https://devenv.sh/reference/options/
}
