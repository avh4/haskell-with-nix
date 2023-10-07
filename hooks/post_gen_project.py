import os
import sys
import subprocess

def run_cabal2nix(cwd, output_filename):
    if "/" in cwd:
        raise ValueError("Not implemented: you'll need to fix relative_root before run_cabal2nix will work with a multi-segment path")

    output_path = os.path.join(cwd, output_filename)
    relative_root = "." if cwd == "." else ".."
    cabal2nix_nix_expr = "(import (import " + relative_root + "/nix/sources.nix).nixpkgs {}).cabal2nix"

    with open(output_path, 'w') as output_file:
        subprocess.run(["nix-shell", "-p", cabal2nix_nix_expr, "--run", "cabal2nix --hpack ."], cwd=cwd, stdout=output_file)

if __name__ == "__main__":
    run_cabal2nix(".", "{{ cookiecutter.project_name }}.nix")
    run_cabal2nix("Shakefile", "default.nix")

    #subprocess.run(["nix-shell", "--run", "./dev/build.sh all"])
