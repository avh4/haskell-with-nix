{ sources ? import ./nix/sources.nix, compiler ? "ghc925", }:
let
  gitignore = import sources."gitignore.nix" { };
  inherit (gitignore) gitignoreSource gitignoreFilterWith;

  haskellPackageOverrides = pkgs: self: super:
    with pkgs.haskell.lib;
    let
      inherit (pkgs) lib;

      mkPkg = name: path: args:
        overrideCabal (self.callCabal2nix name path args) (orig: {
          src = lib.cleanSourceWith {
            name = "source";
            filter = gitignoreFilterWith { basePath = path; };
            src = path;
          };
        });
    in rec {
      {{ cookiecutter.project_name }}-build = mkPkg "{{ cookiecutter.project_name }}-build" ./Shakefile { };
      {{ cookiecutter.project_name }} = mkPkg "{{ cookiecutter.project_name }}" ./. { };
    };

  pkgsForHaskell = import sources.nixpkgs {
    config = {
      packageOverrides = pkgs: rec {
        haskell = pkgs.haskell // {
          packages = pkgs.haskell.packages // {
            project = pkgs.haskell.packages."${compiler}".override {
              overrides = haskellPackageOverrides pkgs;
            };
          };
        };
      };
    };
  };

  haskellPackages = pkgsForHaskell.haskell.packages.project;
  haskellTools = pkgsForHaskell.haskell.packages."${compiler}";
  pkgs = import sources.nixpkgs { };
in {
  {{ cookiecutter.project_name }} = haskellPackages.{{ cookiecutter.project_name }};

  # Make available for shell.nix
  inherit pkgs haskellPackages haskellTools;
}
