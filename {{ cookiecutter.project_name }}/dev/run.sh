#!/bin/bash
set -euxo pipefail

hpack
exec cabal --offline run {{ cookiecutter.project_name }} -- "$@"
