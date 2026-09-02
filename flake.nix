{
  description = "My home manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Flake index: home-manager (and any future third-party flake) is reached
    # through omniflake instead of being a direct input.
    # https://omniflake.com/docs/using
    omniflake.url = "github:fzakaria/omniflake";
    omniflake.inputs.nixpkgs.follows = "nixpkgs";

    #pin to nvim 11.2 - an exact revision, which the index cannot name
    nixpkgs-neovim.url = "github:NixOS/nixpkgs/832efc09b4caf6b4569fbf9dc01bec3082a00611";
  };

  outputs = {nixpkgs, nixpkgs-neovim, omniflake, ...} :
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {inherit system;};
      pkgs-neovim = import nixpkgs-neovim {inherit system;};
      username = "tianluo";
      # nixpkgs follows above, so this home-manager evaluates against ours
      home-manager = omniflake.flakes.home-manager;
    in {
      homeConfigurations."${username}" = 
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit pkgs-neovim; };
          modules = [ ./home.nix ];
        };
    };
}
