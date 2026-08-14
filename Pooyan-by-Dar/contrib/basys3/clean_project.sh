#!/usr/bin/env bash
set -euo pipefail

GAME_DIR="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
REV="vhdl_pooyan_rev_0_2_2020_04_26"
BASE="$GAME_DIR/$REV"

# Remove the whole extracted Dar source tree: staged MAME ROMs, generated
# PROM VHDL, the rebuilt make_vhdl_prom, the regenerated Basys 3 project tree
# (basys3/pooyan_basys3/ + its build junk), and the tracked
# make_pooyan_proms.sh. create_project.sh re-extracts everything from
# dloads/ on the next run, so a clean -> run cycle truly regenerates from
# scratch (nothing in contrib/ is ever touched).
[[ "$BASE" == */"$REV" ]] || { echo "error: refusing to remove $BASE" >&2; exit 1; }
rm -rf "$BASE"
echo "removed: $BASE"

rm -f "$GAME_DIR/vivado.log" "$GAME_DIR/vivado.jou"
echo "clean done"
