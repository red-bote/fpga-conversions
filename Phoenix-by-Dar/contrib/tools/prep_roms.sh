#!/bin/bash
# Linux rom-prep for the Phoenix Basys3 port.
#
# 1. Compile make_vhdl_prom from the bundled copy (contrib/tools/make_vhdl_prom.c).
#    The Phoenix Dar archive ships neither tools_prom_src/ nor a .bat, so the
#    generic make_vhdl_prom tool source is tracked in this port's contrib/tools/,
#    and the generator is the reconstructed contrib/tools/make_phoenix_proms.sh.
# 2. Copy make_phoenix_proms.sh + compiled tool into tools/phoenix_unzip/.
# 3. Unzip the romset (~/roms/phoenix.zip) into tools/phoenix_unzip/.
# 4. Run make_phoenix_proms.sh to generate the 7 PROM VHDLs.
#
# Requires the pristine Dar source tree (vhdl_phoenix_DE10_lite/) to be already
# extracted; this script does not download or extract it.
# Roms and the generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_phoenix_DE10_lite"
PROM_DIR="$SRC_DIR/tools/phoenix_unzip"

ROMZIP="${ROMZIP:-$HOME/roms/phoenix.zip}"

step() { printf '\n==> %s\n' "$1"; }

if [ ! -f "$SRC_DIR/rtl_dar/phoenix.vhd" ]; then
    echo "error: source tree not found: $SRC_DIR" >&2
    echo "Run setup_phoenix.sh first." >&2
    exit 1
fi

mkdir -p "$PROM_DIR"
cp "$ROOT/contrib/tools/make_phoenix_proms.sh" "$ROOT/contrib/tools/make_vhdl_prom.c" "$PROM_DIR/"

step "1/4 Compiling make_vhdl_prom on the host"
gcc "$PROM_DIR/make_vhdl_prom.c" -lm -o "$PROM_DIR/make_vhdl_prom"

step "2/4 Staging reconstructed make_phoenix_proms.sh"
chmod +x "$PROM_DIR/make_phoenix_proms.sh" "$PROM_DIR/make_vhdl_prom"

step "3/4 Unzipping romset"
unzip -o "$ROMZIP" -d "$PROM_DIR"

step "4/4 Generating PROM VHDL"
( cd "$PROM_DIR" && ./make_phoenix_proms.sh )

echo
echo "Rom-prep complete. PROM VHDL generated in:"
ls -1 "$PROM_DIR"/*.vhd
