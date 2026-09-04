#!/bin/bash
# Linux rom-prep for the Traverse USA Basys3 port.
#
# 1. Compile make_vhdl_prom from the extracted Dar source tree on the host (gcc).
# 2. Convert make_travusa_proms.bat -> make_travusa_proms.sh.
# 3. Unzip the romset (~/roms/travrusa.zip) into tools/travusa_unzip/.
# 4. Run make_travusa_proms.sh to generate the PROM VHDL.
#
# Requires the pristine Dar source tree
# (vhdl_traverse_usa_rev_0_0_2019_03_16/) to be already extracted; this
# script does not download or extract it.
#
# Romset: the Dar .bat references the 14 files of the travrusa (Traverse USA
# parent) MAME set by their exact canonical names, so no relabeling is needed
# -- the unzipped rom directory is used as-is. Pre/post-flight checks catch a
# wrong/incomplete romset loudly instead of silently producing empty PROMs.
# Roms and the generated PROM VHDL stay local (never distributed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT/vhdl_traverse_usa_rev_0_0_2019_03_16"
PROM_DIR="$SRC_DIR/tools/travusa_unzip"
TOOLS_SRC="$SRC_DIR/tools/tools_prom_src/src"

ROMZIP="${ROMZIP:-$HOME/roms/travrusa.zip}"

INPUT_ROMS=(
    zr1-0.m3 zr1-5.l3 zr1-6a.k3 zr1-7.j3
    zippyrac.001 mr8.3c mr9.3a
    mmi6349.ij
    zr1-8.n3 zr1-9.l3 zr1-10.k3
    tbp24s10.3 tbp18s.2
    mr10.1a
)

OUTPUT_PROMS=(
    travusa_cpu.vhd
    travusa_chr_bit1.vhd travusa_chr_bit2.vhd travusa_chr_bit3.vhd
    travusa_chr_palette.vhd
    travusa_spr_bit1.vhd travusa_spr_bit2.vhd travusa_spr_bit3.vhd
    travusa_spr_palette.vhd travusa_spr_rgb_lut.vhd
    travusa_sound.vhd
)

step() { printf '\n==> %s\n' "$1"; }

if [ ! -f "$TOOLS_SRC/make_vhdl_prom.c" ]; then
    echo "error: source tree not found: $SRC_DIR" >&2
    echo "Run setup_traverse_usa.sh first." >&2
    exit 1
fi

mkdir -p "$PROM_DIR"

step "1/4 Compiling make_vhdl_prom on the host"
gcc "$TOOLS_SRC/make_vhdl_prom.c" -lm -o "$PROM_DIR/make_vhdl_prom"

step "2/4 Converting make_travusa_proms.bat to .sh"
if [ ! -f "$PROM_DIR/make_travusa_proms.bat" ]; then
    echo "error: $PROM_DIR/make_travusa_proms.bat not found" >&2
    exit 1
fi

sed -E \
    -e 's/\r$//' \
    -e '/^rem/d' \
    -e 's/^copy \/B (.*) ([^ ]+)$/cat \1 > \2/' \
    -e 's/ \+ / /g' \
    -e 's/^make_vhdl_prom /.\/make_vhdl_prom /' \
    -e 's/^del /rm /' \
    "$PROM_DIR/make_travusa_proms.bat" > "$PROM_DIR/make_travusa_proms.sh"
sed -i '1i #!/bin/bash' "$PROM_DIR/make_travusa_proms.sh"
chmod +x "$PROM_DIR/make_travusa_proms.sh" "$PROM_DIR/make_vhdl_prom"

step "3/4 Unzipping romset"
unzip -o "$ROMZIP" -d "$PROM_DIR"

step "Pre-flight: verifying all required ROMs are present"
missing=""
for f in "${INPUT_ROMS[@]}"; do
    if [ ! -s "$PROM_DIR/$f" ]; then
        missing="$missing $f"
    fi
done
if [ -n "$missing" ]; then
    echo "error: romset incomplete ($ROMZIP). Missing required ROMs:" >&2
    for f in $missing; do echo "  $f" >&2; done
    echo "Traverse USA needs the travrusa (parent) MAME set:" >&2
    echo "  darfpga .bat -> canonical name mapping." >&2
    exit 1
fi

step "4/4 Generating PROM VHDL"
( cd "$PROM_DIR" && ./make_travusa_proms.sh )

step "Post-flight: verifying all expected PROM VHDL files were generated"
missing=""
for f in "${OUTPUT_PROMS[@]}"; do
    if [ ! -s "$PROM_DIR/$f" ]; then
        missing="$missing $f"
    fi
done
if [ -n "$missing" ]; then
    echo "error: generation incomplete. Missing output PROM VHDL:" >&2
    for f in $missing; do echo "  $f" >&2; done
    exit 1
fi

echo
echo "Rom-prep complete. PROM VHDL generated in:"
ls -1 "$PROM_DIR"/*.vhd
