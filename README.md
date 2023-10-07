An opinionated project template for Haskell applications
with a Nix dev environment.

Encouraged processes:
- [User-centered design](https://methods.18f.gov/)
- [Extreme Programming](https://en.wikipedia.org/wiki/Extreme_programming)

Encouraged tech stack:
- [Haskell](https://www.haskell.org/)
  - [ghc](https://www.haskell.org/ghc/)
  - [cabal](https://www.haskell.org/cabal/)
  - [hpack](https://github.com/sol/hpack) (remove some tedium of updating cabal files)
  - [relude](https://kowainik.github.io/projects/relude) (alternative Prelude)
  - [ghcid](https://github.com/ndmitchell/ghcid) (fast recompile and test watcher)
  - [haskell-language-server](https://github.com/haskell/haskell-language-server) (IDE support)
  - [@lexi-lambda's recommended](https://lexi-lambda.github.io/blog/2018/02/10/an-opinionated-guide-to-haskell-in-2018/) ghc flags and language extensions
  - [ormolu](https://github.com/tweag/ormolu) (code formatting)
- [Nix](https://nixos.org/)
  - [nixpkgs](https://search.nixos.org/packages)
  - nixpkgs's [Haskell ecosystem](https://nixos.wiki/wiki/Haskell)
  - [Gabriella439/haskell-nix](https://github.com/Gabriella439/haskell-nix) (best practices for Haskell development with Nix)
  - [niv](https://github.com/nmattia/niv) (dependency pinning without requiring flakes)
  - [nixfmt](https://github.com/serokell/nixfmt) (code formatting)
- [shake](https://shakebuild.com/) (build scripting)
- [git](https://git-scm.com/) (version control)
- [markdown](https://commonmark.org/) (documentation format)
- [taskell](https://taskell.app/) (kanban boards saved as markdown files)
- [PlantUML](https://plantuml.com/) (plain-text architecture diagrams)


# Getting started

```sh
nix-shell -p cookiecutter --run "cookiecutter https://github.com/avh4/haskell-with-nix.git"
# cd into the new folder
direnv allow
dev/build.sh cabal.project.freeze
git init
git add .
git commit -m "Initialize from template"

dev/run.sh  # Run the app
dev/build.sh  # Compile the app and run tests
dev/build.sh watch  # Re-run tests on changes
dev/build.sh watch:warnings  # Re-run compiler for warnings on changes
dev/build.sh autofix  # Fix formatting and linting errors
dev/build.sh --help  # Print all available build script targets
```
