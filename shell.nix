{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs.buildPackages; [
      nimble
      nim
      sfml
      csfml
    ];
  }
