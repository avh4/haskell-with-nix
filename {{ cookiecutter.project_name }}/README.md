# {{ cookiecutter.project_name }}

TODO: add description


# Development info

You will need to have [nixpkgs](https://nixos.org/download#download-nix),
[direnv](https://direnv.net/docs/installation.html),
and [nix-direnv](https://github.com/nix-community/nix-direnv#installation)
installed.

```bash
direnv allow

taskell dev/Backlog.taskell.md  # View to-do list
dev/build.sh docs  # Create generated documentation
open Design/  # Browse additional project documentation
open dev/Documentation  # Browse additional development documentation

dev/build.sh  # Compile and run tests
dev/run.sh  # Compile and run
```
