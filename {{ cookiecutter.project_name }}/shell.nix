args@{ sources ? import ./nix/sources.nix
, pkgs-taskell ? import sources.nixpkgs-taskell { }, ... }:
let
  default = import ./. args;
  inherit (default) pkgs haskellPackages haskellTools;
in haskellPackages.shellFor {
  name = "{{ cookiecutter.project_name }}";
  packages = p: [ p.{{ cookiecutter.project_name }} p.{{ cookiecutter.project_name }}-build ];
  buildInputs = with pkgs; [
    # Required to build
    cabal-install
    hpack

    # Required to build documentation
    haskellPackages.graphmod
    pandoc

    # Dev tools
    cabal2nix
    git
    niv
    nixfmt
    plantuml
    pkgs-taskell.taskell
    # Must use the same ghc as the project
    haskellTools.ghcid
    haskellTools.haskell-language-server
  ];
}
