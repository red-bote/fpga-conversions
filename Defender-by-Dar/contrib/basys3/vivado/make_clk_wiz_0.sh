#!/bin/bash
# Generate the clk_wiz_0 MMCM IP (100 MHz -> 12 MHz core + 7.16 MHz sound) for
# the Basys3 port and place its Verilog wrappers where defender_basys3.xpr
# expects them.
#
# The sound board wants the pristine 3.58 MHz clock. An exact 3.58 MHz cannot
# come directly off the MMCM (VCO floor ~600 MHz vs max output divide 128:
# 600/3.58 ~= 167 > 128), so clk_out2 is ~7.16 MHz and the top-level wrapper
# divides it by 2 in fabric to ~3.58 MHz (matches the pristine PLL's clock_3p58;
# the sample-based PIA/D-A sound logic tolerates the few-% error).
#
# The main project's .xpr references two imported files (defender_basys3.xpr):
#   sources_1/imports/clk_wiz_0/clk_wiz_0.v
#   sources_1/imports/clk_wiz_0/clk_wiz_0_clk_wiz.v
# The IP is generated here in a throwaway Vivado project named mmcm_12m and
# only those two .v files are copied into the repo. Per project rules this script
# runs from /tmp so vivado.log / vivado.jou stay outside the repository.

set -euo pipefail

VIVADO=/tools/Xilinx/Vivado/2020.2/bin/vivado
PART=xc7a35tcpg236-1

# Absolute path to this repo's basys3 port tree.
XPR_DIR="$(cd "$(dirname "$0")/../../../vhdl_defender_rev_0_0_2017_10_15/basys3" && pwd)"
CLK_WIZ_IMPORT_DIR="$XPR_DIR/defender_basys3.srcs/sources_1/imports/clk_wiz_0"

# Throwaway project location (logs stay outside the repo).
WORK=/tmp/mmcm_12m
TCL=$WORK/gen_clk_wiz_0.tcl

rm -rf "$WORK"
mkdir -p "$WORK"

cat > "$TCL" <<EOF
create_project mmcm_12m "$WORK" -part $PART -force

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 \
    -module_name clk_wiz_0 -dir "$WORK"

set_property -dict [list \
    CONFIG.PRIMITIVE {MMCM} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.CLKIN1_JITTER_PS {50.0} \
    CONFIG.CLKOUT1_USED {true} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {12} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {7.16} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
] [get_ips clk_wiz_0]

generate_target all [get_ips clk_wiz_0]
EOF

"$VIVADO" -mode batch -nolog -nojournal -source "$TCL"

GEN_DIR="$WORK/clk_wiz_0"
mkdir -p "$CLK_WIZ_IMPORT_DIR"
cp "$GEN_DIR/clk_wiz_0.v"            "$CLK_WIZ_IMPORT_DIR/"
cp "$GEN_DIR/clk_wiz_0_clk_wiz.v"    "$CLK_WIZ_IMPORT_DIR/"

rm -rf "$WORK"

echo "Generated clk_wiz_0 IP files:"
ls -l "$CLK_WIZ_IMPORT_DIR"
