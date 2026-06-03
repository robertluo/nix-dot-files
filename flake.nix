{
  description = "My home manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
 
  outputs = {self, nixpkgs, home-manager, ...} :
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {inherit system;};
      username = "tianluo";
    in {
      homeConfigurations."${username}" = 
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
        };
    };
}
