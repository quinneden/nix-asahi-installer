{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    asahi-installer = {
      url = "github:AsahiLinux/asahi-installer";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, asahi-installer, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        { config, pkgs, ... }:
        {
          packages.default = config.packages.asahi-installer;

          packages.asahi-installer = pkgs.callPackage ./default.nix { inherit inputs; };
        };
    };
}
