#!/bin/bash
# Initial project setup for the Pooyan Basys3 port.
#
# 1. Download & extract the upstream Dar source archive (vhdl_pooyan_rev_0_2_2020_04_26.zip)
#    into the repo root as vhdl_pooyan_rev_0_2_2020_04_26/.
# 2. Apply contrib/basys3/code/pooyan_t80_xor_width.patch to rtl_t80_350/T80.vhd (idempotent).
# 3. Build make_vhdl_prom from source on the host (gcc) and generate make_pooyan_proms.sh
#    from make_pooyan_proms.bat.
# 4. Unzip the romset (~/roms/pooyan.zip) into tools/pooyan_unzip/ and run make_pooyan_proms.sh
#    to generate the PROM VHDL.
# 5. Copy the ported assets from contrib/basys3/code/ and contrib/basys3/vivado/ into the project tree.
#
# clk_wiz_0 IP generation and the pooyan_basys3.vhd top level are separate steps.
# Roms and generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CONTRIB="$ROOT/contrib/basys3"
SRC_DIR="$ROOT/vhdl_pooyan_rev_0_2_2020_04_26"
PROM_DIR="$SRC_DIR/tools/pooyan_unzip"
TOOLS_SRC="$SRC_DIR/tools/tools_prom_src/src"

URL="https://sourceforge.net/projects/darfpga/files/Software%20VHDL/pooyan/vhdl_pooyan_rev_0_2_2020_04_26.zip/download"
ROMZIP="${ROMZIP:-$HOME/roms/pooyan.zip}"

WORK=/tmp/pooyan_setup
ZIP="$WORK/vhdl_pooyan_rev_0_2_2020_04_26.zip"

step() { printf '\n==> %s\n' "$1"; }

rm -rf "$WORK"
mkdir -p "$WORK"

step "1/6 Downloading source archive"
wget -O "$ZIP" "$URL"

step "2/6 Extracting vhdl_pooyan_rev_0_2_2020_04_26/ into repo root"
mkdir -p "$SRC_DIR"
unzip -o "$ZIP" -d "$ROOT"

step "3/6 Applying T80 xor-width patch"
T80="$SRC_DIR/rtl_t80_350/T80.vhd"
if grep -q "RB: modified for Vivado" "$T80"; then
    echo "already applied, skipping"
else
    patch -p1 < "$CONTRIB/code/pooyan_t80_xor_width.patch"
fi

step "4/6 Building make_vhdl_prom and generating make_pooyan_proms.sh"
gcc "$TOOLS_SRC/make_vhdl_prom.c" -lm -o "$PROM_DIR/make_vhdl_prom"

sed -E \
    -e 's/\r$//' \
    -e 's/^copy \/B (.*) ([^ ]+)$/cat \1 > \2/' \
    -e 's/ \+ / /g' \
    -e 's/^make_vhdl_prom /.\/make_vhdl_prom /' \
    -e 's/^del /rm /' \
    "$PROM_DIR/make_pooyan_proms.bat" > "$PROM_DIR/make_pooyan_proms.sh"
sed -i '1i #!/bin/bash' "$PROM_DIR/make_pooyan_proms.sh"
chmod +x "$PROM_DIR/make_pooyan_proms.sh" "$PROM_DIR/make_vhdl_prom"

step "5/6 Generating PROM VHDL from romset"
unzip -o "$ROMZIP" -d "$PROM_DIR"
( cd "$PROM_DIR" && ./make_pooyan_proms.sh )

step "6/6 Copying ported assets into the project"
XPR_DIR="$SRC_DIR/basys3/pooyan_basys3"
CONSTRS_IMPORT="$XPR_DIR/pooyan_basys3.srcs/constrs_1/imports/digilent-xdc-master"
SOURCES_IMPORT="$XPR_DIR/pooyan_basys3.srcs/sources_1/imports/deca"

mkdir -p "$CONSTRS_IMPORT" "$SOURCES_IMPORT"
cp -f "$CONTRIB/vivado/pooyan_basys3.xpr" "$XPR_DIR/pooyan_basys3.xpr"
cp -f "$CONTRIB/vivado/pooyan_basys3.xdc"  "$CONSTRS_IMPORT/Basys-3-Master.xdc"
cp -f "$CONTRIB/code/vga_scandoubler.v"  "$SOURCES_IMPORT/vga_scandoubler.v"

rm -rf "$WORK"

echo
echo "Setup complete. Files in place:"
ls -l "$XPR_DIR/pooyan_basys3.xpr"
ls -l "$CONSTRS_IMPORT/Basys-3-Master.xdc"
ls -l "$SOURCES_IMPORT/vga_scandoubler.v"
echo
echo "Remaining steps (separate): make_clk_wiz_0.sh and creating pooyan_basys3.vhd top level."