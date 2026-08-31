#!/bin/bash
# Linux rom-prep for the Defender Basys3 port.
#
# 1. Compile make_vhdl_prom from the extracted Dar source tree on the host (gcc).
# 2. Convert make_defender_proms.bat -> make_defender_proms.sh. The .bat's
#    11-file `copy /B a + b + ... -> defender_prog.bin` concat is turned into
#    `cat a b ... > defender_prog.bin` by the ` \+ / /g` rule (which collapses
#    the space-plus-space separators after the copy->cat rewrite).
# 3. Unzip the romset (~/roms/defender.zip) into tools/defender_unzip/.
# 4. Run make_defender_proms.sh to generate the PROM VHDL.
#
# Requires the pristine Dar source tree (vhdl_defender_rev_0_0_2017_10_15/)
# to be already extracted; this script does not download or extract it.
# Roms and the generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_defender_rev_0_0_2017_10_15"
PROM_DIR="$SRC_DIR/tools/defender_unzip"
TOOLS_SRC="$SRC_DIR/tools/tools_prom_src/src"

ROMZIP="${ROMZIP:-$HOME/roms/defender.zip}"

step() { printf '\n==> %s\n' "$1"; }

if [ ! -f "$TOOLS_SRC/make_vhdl_prom.c" ]; then
    echo "error: source tree not found: $SRC_DIR" >&2
    echo "Run setup_defender.sh first." >&2
    exit 1
fi

mkdir -p "$PROM_DIR"

step "1/4 Compiling make_vhdl_prom on the host"
gcc "$TOOLS_SRC/make_vhdl_prom.c" -lm -o "$PROM_DIR/make_vhdl_prom"

step "2/4 Converting make_defender_proms.bat to .sh"
if [ ! -f "$PROM_DIR/make_defender_proms.bat" ]; then
    echo "error: $PROM_DIR/make_defender_proms.bat not found" >&2
    exit 1
fi

sed -E \
    -e 's/\r$//' \
    -e '/^rem/d' \
    -e 's/^copy \/B (.*) ([^ ]+)$/cat \1 > \2/' \
    -e 's/ \+ / /g' \
    -e 's/^make_vhdl_prom /.\/make_vhdl_prom /' \
    -e 's/^del /rm /' \
    "$PROM_DIR/make_defender_proms.bat" > "$PROM_DIR/make_defender_proms.sh"
sed -i '1i #!/bin/bash' "$PROM_DIR/make_defender_proms.sh"
chmod +x "$PROM_DIR/make_defender_proms.sh" "$PROM_DIR/make_vhdl_prom"

step "3/4 Unzipping romset"
unzip -o "$ROMZIP" -d "$PROM_DIR"

step "4/4 Generating PROM VHDL"
( cd "$PROM_DIR" && ./make_defender_proms.sh )

echo
echo "Rom-prep complete. PROM VHDL generated in:"
ls -1 "$PROM_DIR"/*.vhd
