#!/bin/bash
# Download, extract, and patch the Galaga Dar source archive, then chain
# into the rom-prep script.
#
# 1. Download vhdl_galaga_rev_0_3_2018_05_06.zip from SourceForge.
# 2. Extract it into the repo root as vhdl_galaga_rev_0_3_2018_05_06/.
# 3. Apply any fix patches idempotently (patch -p1 --forward).
#    Glob covers both contrib/<dir>/code/*.patch (e.g. contrib/basys3/code/)
#    and the flat contrib/code/ (e.g. galaga_credit_mode_fix.patch).
#    Excludes *_de10_lite_to_basys3.patch: that file is a record of the
#    top-level rewrite (authored by make_de10_lite_to_basys3_patch.sh, applied
#    to a different target file), not a fix to apply to the pristine tree.
#    Excludes *scandoubler_fix.patch: applied later to the imported scandoubler
#    copy by create_project.sh, not to the pristine Dar tree.
# 4. Run contrib/tools/prep_roms.sh (compile make_vhdl_prom, convert .bat,
#    unzip romsets, generate PROM VHDL).
#
# Roms and the generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_galaga_rev_0_3_2018_05_06"

URL="https://sourceforge.net/projects/darfpga/files/Software%20VHDL/galaga/vhdl_galaga_rev_0_3_2018_05_06.zip/download"

WORK=/tmp/galaga_setup
ZIP="$WORK/vhdl_galaga_rev_0_3_2018_05_06.zip"

step() { printf '\n==> %s\n' "$1"; }

rm -rf "$WORK"
mkdir -p "$WORK"

step "1/4 Downloading source archive"
wget -O "$ZIP" "$URL"

step "2/4 Extracting vhdl_galaga_rev_0_3_2018_05_06/ into repo root"
mkdir -p "$SRC_DIR"
unzip -o "$ZIP" -d "$ROOT"

step "3/4 Applying fix patches (contrib/*/code/*.patch and contrib/code/*.patch)"
for p in "$ROOT"/contrib/*/code/*.patch "$ROOT"/contrib/code/*.patch; do
    [ -e "$p" ] || continue
    case "$p" in
        *_de10_lite_to_basys3.patch) continue ;;
        *scandoubler_fix.patch) continue ;;
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