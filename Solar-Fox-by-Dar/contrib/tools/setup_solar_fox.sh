#!/bin/bash
# Download, extract, and patch the Solar Fox Dar source archive, then chain
# into the rom-prep script.
#
# 1. Fetch vhdl_solar_fox_rev_0_1_2019_11_22.zip from SourceForge into the cache
#    dloads/ dir (gitignored). Reuses the cached copy if its SHA-256 matches the
#    embedded hash; re-downloads if missing, tampered, or compromised.
# 2. Extract it into the repo root as vhdl_solar_fox_rev_0_1_2019_11_22/.
# 3. Apply any fix patches idempotently (patch -p1 --forward).
#    Glob covers both contrib/<dir>/code/*.patch and contrib/code/*.patch.
# 4. Run contrib/tools/prep_roms.sh (compile make_vhdl_prom, convert .bat,
#    unzip romsets, generate PROM VHDL).
#
# Roms and the generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_solar_fox_rev_0_1_2019_11_22"

URL="https://sourceforge.net/projects/darfpga/files/Software%20VHDL/Solarfox/vhdl_solar_fox_rev_0_1_2019_11_22.zip/download"
EXPECTED_SHA256="2c78e449c8906f08131f8a48e2f495373fd7855934ebae39d9ba8782b6c21d31"

DLOAD_DIR="$ROOT/dloads"
ZIP="$DLOAD_DIR/vhdl_solar_fox_rev_0_1_2019_11_22.zip"

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

step "2/4 Extracting vhdl_solar_fox_rev_0_1_2019_11_22/ into repo root"
mkdir -p "$SRC_DIR"
unzip -o "$ZIP" -d "$ROOT"

step "3/4 Applying fix patches (contrib/*/code/*.patch and contrib/code/*.patch)"
for p in "$ROOT"/contrib/*/code/*.patch "$ROOT"/contrib/code/*.patch; do
    [ -e "$p" ] || continue
    echo "==> applying $p"
    patch -p1 --forward < "$p"
done

step "4/4 Running rom-prep"
"$ROOT/contrib/tools/prep_roms.sh"

echo
echo "Setup complete. Source tree in:"
echo "  $SRC_DIR"