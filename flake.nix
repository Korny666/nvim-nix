{
  description = "Standalone neovim";

  inputs = {
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
    }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      vimconfig = import ./nix-nvim-config.nix;
    in
    {
      nixosModules.default = { pkgs, lib, ... }:
        let
          sys = pkgs.stdenv.hostPlatform.system;
        in {
          environment.systemPackages = [
            (self.packages.${sys}.default or (throw "nvim-nix: unsupported system ${sys}"))
          ];
        };

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          nix-nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
            inherit pkgs;
            module = vimconfig;
          };
          nix-nvim-offline = pkgs.writeShellApplication {
            name = "nvim";
            runtimeInputs = [
              pkgs.bubblewrap
              self.packages.${system}.nix-nvim
              pkgs.bash
            ];
            text = ''
              bwrap --dev-bind / / --unshare-net ${nixpkgs.lib.getExe self.packages.${system}.nix-nvim} "$@"
            '';
          };
          default = self.packages.${system}.nix-nvim;
          fonts = pkgs.nerd-fonts.inconsolata-go;
        }
      );
    };
}
