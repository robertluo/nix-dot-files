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

    # Jolt, a Clojure on Chez Scheme. The omniflake index does not carry it, so
    # it is a direct input. Two details are load-bearing:
    #   - the URL must be git+https with ?submodules=1. Jolt vendors its Scheme
    #     dependencies (irregex, sci, fs, process, grenadine) as git submodules,
    #     and the github: fetcher reads the tarball API, which omits them — the
    #     vendor/ directories arrive empty and the build dies on a missing
    #     vendor/irregex/irregex.scm.
    #   - nix.conf must enable the flake-self-attrs experimental feature, since
    #     Jolt's own flake sets inputs.self.submodules. Lix gates that attribute,
    #     and locking this input evaluates it, so the feature is required here
    #     and not only when building Jolt directly.
    jolt.url = "git+https://github.com/jolt-lang/jolt?submodules=1";
    jolt.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {nixpkgs, nixpkgs-neovim, nixpkgs-devenv, omniflake, jolt, ...} :
    let
      inherit (nixpkgs) lib;
      username = "tianluo";

      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [
          # hold neovim on 0.11; everything else rides unstable
          (_: _: { inherit (nixpkgs-neovim.legacyPackages.${system}) neovim-unwrapped; })
          # hold devenv on 2.2.2
          (_: _: { inherit (nixpkgs-devenv.legacyPackages.${system}) devenv; })
        ]
        # nixpkgs has no jolt; surface the flake's package so home.nix can list
        # a plain pkgs.jolt, like the pinned packages above. Jolt only builds
        # for aarch64-darwin and x86_64-linux, so on any other system the
        # overlay is skipped and home.nix drops the package along with it.
        ++ lib.optional (jolt.packages ? ${system})
          (_: _: { jolt = jolt.packages.${system}.default; });
      };

      # nixpkgs follows above, so these evaluate against our package set
      home-manager = omniflake.flakes.home-manager;
      doom-emacs = omniflake.flakes.nix-doom-emacs-unstraightened;

      # gui = false is the headless profile: no terminal emulator, no neovide,
      # and Emacs built without the GTK/X closure.
      mkHome = { system, gui }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = { inherit gui username; };
          modules = [ ./home.nix doom-emacs.homeModule ];
        };

      darwin = mkHome { system = "aarch64-darwin"; gui = true; };
    in {
      # Every machine answers to "<user>@<system>", which is what the devenv
      # `apply` script uses. The Mac additionally keeps the bare "<user>" name,
      # since that is where `home-manager switch --flake .` lands when no
      # <user>@<hostname> attribute matches.
      homeConfigurations = {
        "${username}" = darwin;
        "${username}@aarch64-darwin" = darwin;
        "${username}@x86_64-linux" = mkHome { system = "x86_64-linux"; gui = false; };
        "${username}@aarch64-linux" = mkHome { system = "aarch64-linux"; gui = false; };
      };
    };
}
