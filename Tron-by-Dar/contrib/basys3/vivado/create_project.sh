#!/bin/bash
# Create the initial Vivado Basys3 project for the Tron port in the extracted
# Dar source tree, and copy the tracked port assets into place.
#
# Layout is non-nested (unlike Pooyan): the .xpr lives directly in basys3/ and
# the project sources tree is basys3/tron_basys3.srcs/.
#
# 1. Create the project dirs.
# 2. Copy the .xpr into place.
# 3. Copy Basys-3-Master.xdc into constrs_1/imports/digilent-xdc-master/.
#
# The core generates progressive 31 kHz video natively (tv15Khz_mode), same as
# the sibling Kick-Midway-MCR-by-Dar port, so no external scandoubler is
# imported.
#
# clk_wiz_0 IP generation (make_clk_wiz_0.sh) and the top level
# (make_de10_lite_to_basys3_patch.sh) are separate; the tracked .xpr already
# references their expected output paths (and the not-yet-generated PROM VHDL
# under tools/tron_unzip/), which Vivado shows as missing sources until those
# steps (and `make setup` with a real ROMZIP) have run.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SRC_DIR="$ROOT/vhdl_tron_rev_0_3_2019_11_22"
CONTRIB="$ROOT/contrib/basys3"

PROJ_DIR="$SRC_DIR/basys3"
CONSTRS_IMPORT="$PROJ_DIR/tron_basys3.srcs/constrs_1/imports/digilent-xdc-master"

if [ ! -d "$SRC_DIR" ]; then
    echo "error: source tree not found: $SRC_DIR" >&2
    echo "Run contrib/tools/setup_tron.sh first." >&2
    exit 1
fi

step() { printf '\n==> %s\n' "$1"; }

step "1/3 Creating project directories"
mkdir -p "$PROJ_DIR" "$CONSTRS_IMPORT"

step "2/3 Copying tron_basys3.xpr"
cp -f "$CONTRIB/vivado/tron_basys3.xpr" "$PROJ_DIR/tron_basys3.xpr"

step "3/3 Copying Basys-3-Master.xdc"
cp -f "$CONTRIB/vivado/Basys-3-Master.xdc" "$CONSTRS_IMPORT/Basys-3-Master.xdc"

echo
echo "Project files in place:"
ls -l "$PROJ_DIR/tron_basys3.xpr"
ls -l "$CONSTRS_IMPORT/Basys-3-Master.xdc"
