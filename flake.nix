{
  description = "My home manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Flake index: home-manager (and any future third-party flake) is reached
    # through omniflake instead of being a direct input.
    # https://omniflake.com/docs/using
    omniflake.url = "github:fzakaria/omniflake";
    omniflake.inputs.nixpkgs.follows = "nixpkgs";

    # nixpkgs ships exactly one neovim, and unstable is on the 0.12 series.
    # This second nixpkgs exists only to supply neovim-unwrapped; the overlay
    # below is the only place it is used.
    nixpkgs-neovim.url = "github:NixOS/nixpkgs/832efc09b4caf6b4569fbf9dc01bec3082a00611";

    # Same trick for devenv, held on 2.2.2: unstable's 2.3.1 carries a
    # regression. This is the last master commit before the 2.2.2 -> 2.3.0 bump.
    nixpkgs-devenv.url = "github:NixOS/nixpkgs/aa88e342b757ea13a06cb6f7fc8c00a8e1d2bb64";
  };

  outputs = {nixpkgs, nixpkgs-neovim, nixpkgs-devenv, omniflake, ...} :
    let
      inherit (nixpkgs) lib;

      # Machines differ by user and by system. `apply` resolves
      # <whoami>@<currentSystem>, so a new box needs no change here as long as
      # its pair is covered by these two lists.
      usernames = [ "tianluo" "admin" ];
      systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];

      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [
          # hold neovim on 0.11; everything else rides unstable
          (_: _: { inherit (nixpkgs-neovim.legacyPackages.${system}) neovim-unwrapped; })
          # hold devenv on 2.2.2
          (_: _: { inherit (nixpkgs-devenv.legacyPackages.${system}) devenv; })
        ];
      };

      # one package set per system, imported at most once each however many
      # users share it
      pkgsBySystem = lib.genAttrs systems mkPkgs;

      # nixpkgs follows above, so these evaluate against our package set
      home-manager = omniflake.flakes.home-manager;
      doom-emacs = omniflake.flakes.nix-doom-emacs-unstraightened;

      # gui is a property of the machine, not of the user. Only the Mac has a
      # screen today, so it tracks the system; a Linux desktop would override
      # this one line. home.nix still treats gui and isDarwin as separate axes.
      guiFor = system: system == "aarch64-darwin";

      mkHome = { system, username }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsBySystem.${system};
          extraSpecialArgs = { inherit username; gui = guiFor system; };
          modules = [ ./home.nix doom-emacs.homeModule ];
        };
    in {
      # "<user>@<system>" for every pair, which is what `apply` builds. The bare
      # "tianluo" stays as the Mac's fallback, since that is where
      # `home-manager switch --flake .` lands when no <user>@<hostname> matches.
      homeConfigurations =
        lib.listToAttrs (
          map (c: lib.nameValuePair "${c.username}@${c.system}" (mkHome c)) (
            lib.cartesianProduct {
              username = usernames;
              system = systems;
            }
          )
        )
        // {
          "tianluo" = mkHome {
            username = "tianluo";
            system = "aarch64-darwin";
          };
        };
    };
}
