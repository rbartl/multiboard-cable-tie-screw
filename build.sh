#!/usr/bin/env bash
# Renders every part/size combination into stl/.
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p stl

for size in S M L; do
    for part in body nut; do
        openscad --backend manifold \
            -D "size=\"$size\"" -D "part=\"$part\"" \
            -o "stl/cable_tie_${size}_${part}.stl" src/cable_tie.scad
    done
done

ls -la stl/
