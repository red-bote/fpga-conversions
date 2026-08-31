#!/bin/bash
# Reconstructed Phoenix PROM generator.
#
# The upstream vhdl_phoenix_DE10_lite.zip ships without the DE2 release's
# tools/make_phoenix_proms.bat (and without tools_prom_src/). This script
# reconstructs that .bat from the DE2 README's 14-ROM -> VHDL mapping, verified
# against the entities phoenix.vhd instantiates:
#
#   ic45 + ic46 + ic47 + ic48 + h5-ic49.5a + h6-ic50.6a +
#   h7-ic51.7a + h8-ic52.8a   -> phoenix_prog.vhd       (16K program, cpu_adr(13:0))
#   b1-ic39.3b                -> prom_ic39.vhd          (foreground graphix bit0)
#   b2-ic40.4b                -> prom_ic40.vhd          (foreground graphix bit1)
#   ic23.3d                   -> prom_ic23.vhd          (background graphix bit0)
#   ic24.4d                   -> prom_ic24.vhd          (background graphix bit1)
#   mmi6301.ic40              -> prom_palette_ic40.vhd  (RGB low intensity)
#   mmi6301.ic41              -> prom_palette_ic41.vhd  (RGB high intensity)
#
# make_vhdl_prom derives each entity's name from the output filename and infers
# the addr width from the byte length, so the generated entity names and widths
# match the port maps in phoenix.vhd exactly.

set -euo pipefail

cd "$(dirname "$0")"

cat ic45 ic46 ic47 ic48 h5-ic49.5a h6-ic50.6a h7-ic51.7a h8-ic52.8a > phoenix_prog.bin

./make_vhdl_prom phoenix_prog.bin phoenix_prog.vhd
./make_vhdl_prom b1-ic39.3b prom_ic39.vhd
./make_vhdl_prom b2-ic40.4b prom_ic40.vhd
./make_vhdl_prom ic23.3d prom_ic23.vhd
./make_vhdl_prom ic24.4d prom_ic24.vhd
./make_vhdl_prom mmi6301.ic40 prom_palette_ic40.vhd
./make_vhdl_prom mmi6301.ic41 prom_palette_ic41.vhd
