#!/bin/bash
# Download, extract, and patch the Computer Space Dar source archive.
#
# 1. Fetch vhdl_computer_space_rev_1_1_2017_11_22.zip from SourceForge into
#    the cache dloads/ dir (gitignored). Reuses the cached copy if its SHA-256
#    matches the embedded hash; re-downloads if missing, tampered, or
#    compromised.
# 2. Extract it into the repo root as vhdl_computer_space_rev_1_1_2017_11_22/.
# 3. Apply any fix patches idempotently.
#    Glob covers both contrib/<dir>/code/*.patch and contrib/code/*.patch.
#    Excludes *_de10_lite_to_basys3.patch: that file is a record of the
#    top-level rewrite (authored by make_de10_lite_to_basys3_patch.sh, applied
#    to a different target file), not a fix to apply to the pristine tree.
# 4. Verify the six sound-waveform .hex files exist in the extracted rtl/
#    directory, then run gen_sound_roms.py to generate the six rom_*.vhd
#    replacements into basys3/generated_sound_roms/ (gitignored).
#
# Computer Space is fundamentally different from other Dar ports: it has no
# ROMs, no tools/ directory, no make_vhdl_prom, and no .bat files. The sound
# waveform data is stored in .hex files already present in the rtl/ directory.
# The original Altera altsyncram blocks initialized from these Intel-HEX files.
# Rather than reading them with textio at synthesis time (which fails: the
# paths are CWD-relative and the .hex are Intel-HEX records, not plain bytes),
# the generator parses the .hex and emits regular VHDL with inline ROM content,
# so synthesis infers BRAM without touching any .hex file.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_computer_space_rev_1_1_2017_11_22"

URL="https://sourceforge.net/projects/darfpga/files/Software%20VHDL/computer_space/vhdl_computer_space_rev_1_1_2017_11_22.zip/download"
EXPECTED_SHA256="706ee25e84e22bbf115ad63fb4821feeb4f1c0d83971076b3be08070ac502a51"

DLOAD_DIR="$ROOT/dloads"
ZIP="$DLOAD_DIR/vhdl_computer_space_rev_1_1_2017_11_22.zip"

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

step "2/4 Extracting vhdl_computer_space_rev_1_1_2017_11_22/ into repo root"
mkdir -p "$SRC_DIR"
unzip -o "$ZIP" -d "$ROOT"

step "3/4 Applying fix patches (contrib/*/code/*.patch and contrib/code/*.patch)"
for p in "$ROOT"/contrib/*/code/*.patch "$ROOT"/contrib/code/*.patch; do
    [ -e "$p" ] || continue
    case "$p" in
        *_de10_lite_to_basys3.patch) continue ;;
        *scandoubler_fix.patch) continue ;; # applied later to the imported scandoubler
    esac
    # --binary: the extracted Dar rtl files are CRLF, so a plain `patch` run
    # (which strips trailing CRs from the patch) cannot match them. --binary
    # keeps CRs in both patch and target so CRLF-authored .patch files apply.
    if (cd "$ROOT" && patch --binary -p1 -R --dry-run --forward < "$p" > /dev/null 2>&1); then
        echo "==> already applied, skipping $p"
    else
        echo "==> applying $p"
        (cd "$ROOT" && patch --binary -p1 --forward < "$p")
    fi
done

step "Verifying hex files in rtl/"
HEX_FILES="bakamb_8_11.hex explosion_8_11.hex rotate_8_11.hex rocket_shooting_8_11.hex thrust_8_11.hex saucer_shooting_8_11.hex"
missing=0
for h in $HEX_FILES; do
    if [ ! -f "$SRC_DIR/rtl/$h" ]; then
        echo "ERROR: missing hex file: $SRC_DIR/rtl/$h" >&2
        missing=$((missing + 1))
    fi
done
if [ "$missing" -gt 0 ]; then
    echo "ERROR: $missing hex file(s) missing" >&2
    exit 1
fi

step "4/4 Generating rom_*.vhd sound ROMs from the .hex files"
GEN_DIR="$SRC_DIR/basys3/generated_sound_roms"
python3 "$ROOT/contrib/tools/gen_sound_roms.py" "$SRC_DIR/rtl" "$GEN_DIR"

echo
echo "Setup complete. Source tree in:"
echo "  $SRC_DIR"
echo "Sound ROM replacements in (gitignored):"
echo "  $GEN_DIR"
