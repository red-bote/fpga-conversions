#!/usr/bin/env bash
# Generate the Pooyan PROM VHDL from the staged MAME ROMs.
# Port of the Dar make_pooyan_proms.bat. Run from this directory
# (tools/pooyan_unzip/), after unzipping MAME pooyan.zip here.
# Requires ./make_vhdl_prom (rebuilt from tools_prom_src/src/make_vhdl_prom.c:
#   gcc make_vhdl_prom.c -lm)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"
PROM="$here/make_vhdl_prom"

cat 1.4a 2.5a 3.6a 4.7a > pooyan_prog.bin
cat xx.7a xx.8a > pooyan_sound.bin

"$PROM" pooyan_prog.bin pooyan_prog.vhd
"$PROM" 6.9a pooyan_sprite_grphx1.vhd
"$PROM" 5.8a pooyan_sprite_grphx2.vhd
"$PROM" 8.10g pooyan_char_grphx1.vhd
"$PROM" 7.9g pooyan_char_grphx2.vhd
"$PROM" pooyan_sound.bin pooyan_sound_prog.vhd
"$PROM" pooyan.pr1 pooyan_palette.vhd
"$PROM" pooyan.pr3 pooyan_char_color_lut.vhd
"$PROM" pooyan.pr2 pooyan_sprite_color_lut.vhd

rm pooyan_prog.bin pooyan_sound.bin
