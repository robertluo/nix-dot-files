{
  description = "My home manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    #pin to nvim 11.2
    nixpkgs-neovim.url = "github:NixOS/nixpkgs/832efc09b4caf6b4569fbf9dc01bec3082a00611";
  };
 
  outputs = {self, nixpkgs, nixpkgs-neovim, home-manager, ...} :
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {inherit system;};
      pkgs-neovim = import nixpkgs-neovim {inherit system;};
      username = "tianluo";
    in {
      homeConfigurations."${username}" = 
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit pkgs-neovim; };
          modules = [ ./home.nix ];
        };
    };
}
