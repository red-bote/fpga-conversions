#!/bin/bash
# Download, extract, and patch the Zaxxon Dar source archive, then chain
# into the rom-prep script.
#
# 1. Fetch vhdl_zaxxon_rev_0_0_2019_11_29.zip from SourceForge into the cache
#    dloads/ dir (gitignored). Reuses the cached copy if its SHA-256 matches the
#    embedded hash; re-downloads if missing, tampered, or compromised.
# 2. Extract it into the repo root as vhdl_zaxxon_rev_0_0_2019_11_29/.
# 3. Apply any fix patches idempotently (patch -p1 --forward).
#    Glob covers both contrib/<dir>/code/*.patch and contrib/code/*.patch.
#    Excludes *_de10_lite_to_basys3.patch: that file is a record of the
#    top-level rewrite (authored by make_de10_lite_to_basys3_patch.sh, applied
#    to a different target file), not a fix to apply to the pristine tree.
#    Excludes *scandoubler_fix.patch: applied later by create_project.sh to
#    the imported scandoubler copy, not to the pristine tree.
# 4. Run contrib/tools/prep_roms.sh (compile make_vhdl_prom, convert .bat,
#    unzip romset, generate PROM VHDL).
#
# Roms and the generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_zaxxon_rev_0_0_2019_11_29"

URL="https://sourceforge.net/projects/darfpga/files/Software%20VHDL/zaxxon/vhdl_zaxxon_rev_0_0_2019_11_29.zip/download"
EXPECTED_SHA256="cae40f154bc1fb6cf58cf8b804c495bb89bd5914583bd1bdf426fa8c52f5a4cf"

DLOAD_DIR="$ROOT/dloads"
ZIP="$DLOAD_DIR/vhdl_zaxxon_rev_0_0_2019_11_29.zip"

step() { printf '\n==> %s\n' "$1"; }

fetch_zip() {
    mkdir -p "$DLOAD_DIR"
    if [ -f "$ZIP" ]; then
        actual=$(sha256sum "$ZIP" | cut -d' ' -f1)
        if [ "$actual" = "$EXPECTED_SHA256" ]; then
            step "Using cached source archive (SHA-256 verified)"
            return
        fi
        echo "WARNING: cached archive hash mismatch; re-downloading" >&2
        rm -f "$ZIP"
    fi
    wget -O "$ZIP" "$URL"
    actual=$(sha256sum "$ZIP" | cut -d' ' -f1)
    if [ "$actual" != "$EXPECTED_SHA256" ]; then
        echo "ERROR: downloaded archive failed SHA-256 integrity check" >&2
        rm -f "$ZIP"
        exit 1
    fi
}

step "1/4 Fetching source archive (cached or verified)"
fetch_zip

step "2/4 Extracting vhdl_zaxxon_rev_0_0_2019_11_29/ into repo root"
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

echo
echo "Setup complete. Source tree in:"
echo "  $SRC_DIR"