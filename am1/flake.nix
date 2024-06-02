{
  description = "System config flake";

  inputs = {
    # NixOS official package source, using the nixos-23.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    valheim-server = {
      url = "github:aidalgol/valheim-server-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, valheim-server, ... }@inputs: {
    nixosConfigurations.am1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        valheim-server.nixosModules.default
      ];
    };
  };
}
