#!/bin/bash
# Download, extract, and patch the Phoenix Dar source archive, then chain into
# the rom-prep script.
#
# 1. Fetch vhdl_phoenix_DE10_lite.zip from SourceForge into the cache dloads/
#    dir (gitignored). Reuses the cached copy if its SHA-256 matches the
#    embedded hash; re-downloads if missing, tampered, or compromised.
# 2. Extract it into the repo root as vhdl_phoenix_DE10_lite/.
#    NOTE: unlike other Dar archives this zip has NO internal top-level folder;
#    its members (rtl_dar/, rtl_T80/, de10_lite/, README.txt) sit at the zip
#    root. We extract into $SRC_DIR explicitly so the standard
#    <vhdl_*>/ layout, gitignore (**.gitignore's **/vhdl_*/*), and `make clean`
#    (which removes $SRC_DIR) all hold.
# 3. Apply any fix patches idempotently (patch -p1 --forward).
#    Glob covers both contrib/<dir>/code/*.patch and contrib/code/*.patch.
#    Excludes *_de10_lite_to_basys3.patch: that file is a record of the
#    top-level rewrite (authored by make_de10_lite_to_basys3_patch.sh, applied
#    to a different target file), not a fix to apply to the pristine tree.
#    Excludes *scandoubler_fix.patch: applied later to the imported scandoubler
#    copy by create_project.sh, not to the pristine Dar tree.
#    contrib/code/phoenix_expose_hsync_vsync.patch expose real hsync/vsync
#    from the core (the pristine design only produces composite sync); see
#    contrib/basys3/PORTING_SPEC.md. An earlier patch adding external
#    coin/start/fire/direction ports to rtl_dar/phoenix.vhd was tried and
#    reverted (no input registered on hardware) -- Phoenix is PS/2-keyboard
#    only.
# 4. Run contrib/tools/prep_roms.sh (compile make_vhdl_prom, run the
#    reconstructed make_phoenix_proms.sh, unzip romset, generate PROM VHDL).
#
# Roms and the generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_phoenix_DE10_lite"

URL="https://sourceforge.net/projects/darfpga/files/Software%20VHDL/phoenix/vhdl_phoenix_DE10_lite.zip/download"
EXPECTED_SHA256="74da205e98a79bfd3e50bb09d204684ee31511d23b55b195061a9c1af9901b46"

DLOAD_DIR="$ROOT/dloads"
ZIP="$DLOAD_DIR/vhdl_phoenix_DE10_lite.zip"

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

step "2/4 Extracting vhdl_phoenix_DE10_lite/ into repo root"
mkdir -p "$SRC_DIR"
unzip -o "$ZIP" -d "$SRC_DIR"

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
