#!/bin/bash
# Download, extract, and patch the Time Pilot Dar source archive, then chain
# into the rom-prep script.
#
# 1. Download vhdl_time_pilot_rev_0_0_2017_11_05.zip from SourceForge.
# 2. Extract it into the repo root as vhdl_time_pilot_rev_0_0_2017_11_05/.
# 3. Apply any synthesis-fix patches under contrib/basys3/code/ (idempotent).
#    Excludes *_de10_lite_to_basys3.patch: that file is a record of the
#    top-level rewrite (authored by make_de10_lite_to_basys3_patch.sh, applied
#    to a different target file), not a fix to apply to the pristine tree.
# 4. Run contrib/tools/prep_roms.sh (compile make_vhdl_prom, convert .bat,
#    unzip romset, generate PROM VHDL).
#
# Roms and the generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_time_pilot_rev_0_0_2017_11_05"
CONTRIB="$ROOT/contrib/basys3"

URL="https://sourceforge.net/projects/darfpga/files/Software%20VHDL/time_pilot/vhdl_time_pilot_rev_0_0_2017_11_05.zip/download"

WORK=/tmp/time_pilot_setup
ZIP="$WORK/vhdl_time_pilot_rev_0_0_2017_11_05.zip"

step() { printf '\n==> %s\n' "$1"; }

rm -rf "$WORK"
mkdir -p "$WORK"

step "1/4 Downloading source archive"
wget -O "$ZIP" "$URL"

step "2/4 Extracting vhdl_time_pilot_rev_0_0_2017_11_05/ into repo root"
mkdir -p "$SRC_DIR"
unzip -o "$ZIP" -d "$ROOT"

step "3/4 Applying synthesis-fix patches"
for p in "$CONTRIB"/code/*.patch; do
    [ -e "$p" ] || continue
    case "$p" in
        *_de10_lite_to_basys3.patch) continue ;;
    esac
    echo "==> applying $p"
    patch -p1 --forward < "$p"
done

step "4/4 Running rom-prep"
"$ROOT/contrib/tools/prep_roms.sh"

rm -rf "$WORK"

echo
echo "Setup complete. Source tree in:"
echo "  $SRC_DIR"