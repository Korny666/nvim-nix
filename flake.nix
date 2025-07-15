{
  description = "Standalone neovim";

  inputs = {
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
    }:
    let
      system = "x86_64-linux";
      vimconfig = import ./nix-nvim-config.nix;
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages."${system}" = {
        nix-nvim = nixvim.legacyPackages."${system}".makeNixvimWithModule {
          inherit pkgs;
          module = vimconfig;
        };
        nix-nvim-offline = pkgs.writeShellApplication {
          name = "nvim";
          runtimeInputs = [
            pkgs.bubblewrap
            self.packages."${system}".nix-nvim
	    pkgs.bash
          ];
          text = ''
            bwrap --dev-bind / / --unshare-net ${nixpkgs.lib.getExe self.packages."${system}".nix-nvim} "$@"
          '';
        };
        default = self.packages."${system}".nix-nvim;
      };
    };
}
