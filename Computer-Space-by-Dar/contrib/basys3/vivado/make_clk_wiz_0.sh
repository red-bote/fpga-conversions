#!/bin/bash
# Generate the clk_wiz_0 MMCM IP (100 MHz -> 6 MHz / 12 MHz / 50 MHz) for the
# Basys3 port and place its Verilog wrappers where computer_space_basys3.xpr
# expects them.
#
# Three clocks, forced to VCO 600 MHz (CLKFBOUT_MULT_F=6, DIVCLK_DIVIDE=1) so
# every output is an exact integer divide and clk_sys is exactly 2x game_clk:
#   clk_out1 = 50 MHz  -> core clock_50 / super_clk (timers, noise, sound)
#   clk_out2 = 6  MHz  -> core game_clk (video pixel clock, keyboard); this is
#                         ce_x1 to the scandoubler
#   clk_out3 = 12 MHz  -> scandoubler clk_sys, EXACTLY 2x game_clk
# The MiST scandoubler requires clk_sys = exactly 2x the ce_x1 (pixel) rate for
# its line-buffer read/write pointers to stay aligned (the proven Phoenix
# convention: clk_sys=11, video_clk=5.5). With any other ratio the read pointer
# drifts against the write pointer and the VGA output goes black with only
# occasional misaligned flashes.
#
# The clk_wiz auto-solver does not pick a VCO that makes 12 an exact integer
# divide (given 50/6/12 it chooses VCO=750, giving clk_out3 = 750/63 =
# 11.90476 MHz, not 12). So after the IP is generated we deterministically
# rewrite the MMCM constants to the VCO=600 set (CLKFBOUT_MULT_F 6.0,
# CLKOUT0_DIVIDE_F 12, CLKOUT1_DIVIDE 100, CLKOUT2_DIVIDE 50), which yields the
# exact 50.000 / 6.000 / 12.000 MHz needed.
# The MMCM cannot generate 5.84 MHz from 100 MHz with a valid VCO (600-1200 MHz),
# so game_clk = 6 MHz (2.7% above Dar's 5.842 MHz). Game timing counters live in
# the clock_50 (50 MHz) domain and are unaffected; only the scan_counter video
# timing scales by 6/5.842 ~ 1.027 (within a 15 kHz TV's horizontal tolerance).
#
# The main project's .xpr references three imported files
# (computer_space_basys3.xpr):
#   sources_1/imports/clk_wiz_0/clk_wiz_0.v
#   sources_1/imports/clk_wiz_0/clk_wiz_0_clk_wiz.v
# The IP is generated here in a throwaway Vivado project named mmcm_computerspace
# and only those .v files are copied into the repo. Per project rules this script
# runs from /tmp so vivado.log / vivado.jou stay outside the repository.

set -euo pipefail

VIVADO=/tools/Xilinx/Vivado/2020.2/bin/vivado
PART=xc7a35tcpg236-1

# Absolute path to this repo's basys3 port tree.
XPR_DIR="$(cd "$(dirname "$0")/../../../vhdl_computer_space_rev_1_1_2017_11_22/basys3" && pwd)"
CLK_WIZ_IMPORT_DIR="$XPR_DIR/computer_space_basys3.srcs/sources_1/imports/clk_wiz_0"

# Throwaway project location (logs stay outside the repo).
WORK=/tmp/mmcm_computerspace
TCL=$WORK/gen_clk_wiz_0.tcl

rm -rf "$WORK"
mkdir -p "$WORK"

cat > "$TCL" <<EOF
create_project mmcm_computerspace "$WORK" -part $PART -force

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 \
    -module_name clk_wiz_0 -dir "$WORK"

set_property -dict [list \
    CONFIG.PRIMITIVE {MMCM} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.CLKIN1_JITTER_PS {50.0} \
    CONFIG.CLKOUT1_USED {true} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {6} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {12} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
] [get_ips clk_wiz_0]

generate_target all [get_ips clk_wiz_0]
EOF

"$VIVADO" -mode batch -nolog -nojournal -source "$TCL"

GEN_DIR="$WORK/clk_wiz_0"
mkdir -p "$CLK_WIZ_IMPORT_DIR"
cp "$GEN_DIR/clk_wiz_0.v"            "$CLK_WIZ_IMPORT_DIR/"
cp "$GEN_DIR/clk_wiz_0_clk_wiz.v"    "$CLK_WIZ_IMPORT_DIR/"

# Force the exact VCO=600 divider set so clk_sys is exactly 2x game_clk
# (see header): CLKFBOUT_MULT_F 6.0, CLKOUT0_DIVIDE_F 12, CLKOUT1_DIVIDE 100,
# CLKOUT2_DIVIDE 50 -> 50.000 / 6.000 / 12.000 MHz.
# The Auto-generated .v is build output inside the gitignored project tree, so
# this rewrite lives only in this tracked script.
MMCM="$CLK_WIZ_IMPORT_DIR/clk_wiz_0_clk_wiz.v"
sed -i \
    -e 's/\.CLKFBOUT_MULT_F *( *[0-9.]* *)/.CLKFBOUT_MULT_F      (6.000)/' \
    -e 's/\.CLKOUT0_DIVIDE_F *( *[0-9.]* *)/.CLKOUT0_DIVIDE_F   (12.000)/' \
    -e 's/\.CLKOUT1_DIVIDE *( *[0-9]* *)/.CLKOUT1_DIVIDE       (100)/' \
    -e 's/\.CLKOUT2_DIVIDE *( *[0-9]* *)/.CLKOUT2_DIVIDE       (50)/' \
    "$MMCM"

echo "Rewrote MMCM constants to VCO=600 (exact 50/6/12):"
grep -n "CLKFBOUT_MULT_F\|CLKOUT0_DIVIDE_F\|CLKOUT1_DIVIDE\|CLKOUT2_DIVIDE" "$MMCM" | sed 's/^/  /'

rm -rf "$WORK"

echo "Generated clk_wiz_0 IP files:"
ls -l "$CLK_WIZ_IMPORT_DIR"
