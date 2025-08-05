{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs.buildPackages; [
      nimble
      nim
      SDL2
      SDL2_image
      SDL2_gfx
      SDL2_ttf
      SDL2_mixer
    ];
  }
