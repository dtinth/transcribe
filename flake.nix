{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
      ];
      perSystem = { config, pkgs, ... }:
        let
          # frameworks = pkgs.swift.apple_sdk.frameworks;
          frameworks = pkgs.swiftPackages.apple_sdk.frameworks;
          transcribe = pkgs.callPackage ./package.nix { };
        in
        {
          packages = {
            inherit transcribe;
            default = transcribe;
          };
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              pkgs.swiftPackages.swift
            ];
            buildInputs = with pkgs; [
              just
              frameworks.Foundation
              frameworks.Speech
              frameworks.AVFoundation
            ];
          };
        };
    };
}
