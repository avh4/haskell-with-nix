#!/bin/bash
set -euo pipefail

hpack --silent
(cd Shakefile && hpack --silent)
exec cabal --offline run build -- "$@"
