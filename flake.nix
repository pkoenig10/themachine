{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.11";
    };
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    {
      nixosConfigurations = {
        themachine = nixpkgs.lib.nixosSystem {
          modules = [
            ./configuration.nix
          ];
        };
      };
    };
}
