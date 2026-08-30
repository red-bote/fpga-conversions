#!/bin/bash
# Download, extract, and patch the Tron Dar source archive, then chain into
# the rom-prep script.
#
# 1. Fetch vhdl_tron_rev_0_3_2019_11_22.zip from SourceForge into the cache
#    dloads/ dir (gitignored). Reuses the cached copy if its SHA-256 matches
#    the embedded hash; re-downloads if missing, tampered, or compromised.
# 2. Extract it into the repo root as vhdl_tron_rev_0_3_2019_11_22/.
# 3. Apply any synthesis-fix patches under contrib/basys3/code/ (idempotent).
#    Excludes *_de10_lite_to_basys3.patch: that file is a record of the
#    top-level rewrite (authored by make_de10_lite_to_basys3_patch.sh, applied
#    to a different target file), not a fix to apply to the pristine tree.
# 4. Run contrib/tools/prep_roms.sh (compile make_vhdl_prom, convert .bat,
#    unzip romset(s), generate PROM VHDL).
#
# Roms and the generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_tron_rev_0_3_2019_11_22"
CONTRIB="$ROOT/contrib/basys3"

URL="https://sourceforge.net/projects/darfpga/files/Software%20VHDL/tron/vhdl_tron_rev_0_3_2019_11_22.zip/download"
EXPECTED_SHA256="62360d4423b8b43578e9b984da2319f21c9aa52edc5a59b7fb2b356314b49ba8"

DLOAD_DIR="$ROOT/dloads"
ZIP="$DLOAD_DIR/vhdl_tron_rev_0_3_2019_11_22.zip"

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

step "2/4 Extracting vhdl_tron_rev_0_3_2019_11_22/ into repo root"
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

echo
echo "Setup complete. Source tree in:"
echo "  $SRC_DIR"
