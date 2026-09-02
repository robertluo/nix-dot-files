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
  };

  outputs = {nixpkgs, nixpkgs-neovim, omniflake, ...} :
    let
      system = "aarch64-darwin";
      username = "tianluo";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # hold neovim on 0.11; everything else rides unstable
          (_: _: { inherit (nixpkgs-neovim.legacyPackages.${system}) neovim-unwrapped; })
        ];
      };
      # nixpkgs follows above, so this home-manager evaluates against ours
      home-manager = omniflake.flakes.home-manager;
    in {
      homeConfigurations."${username}" = 
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
        };
    };
}
