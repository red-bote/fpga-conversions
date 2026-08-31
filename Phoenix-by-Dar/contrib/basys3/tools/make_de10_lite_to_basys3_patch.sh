#!/bin/bash
# Generate the patch that adapts the upstream DE10-lite top level
# (rtl_dar/phoenix_de10_lite.vhd) into the Basys3 top level
# (phoenix_basys3.vhd).
#
# The target phoenix_basys3.vhd is authored here (it is a full rewrite of the
# top-level wrapper). The script:
#   1. Writes the target VHDL to a scratch dir.
#   2. Diffs it against the pristine upstream source to produce the git-style
#      patch at contrib/basys3/code/phoenix_de10_lite_to_basys3.patch
#      (matching the Pooyan/Time-Pilot/Bagman/Berzerk convention; the fix
#      patches stay flat in contrib/code/).
#   3. Places the target where phoenix_basys3.xpr expects it
#      (basys3/phoenix_basys3.srcs/sources_1/new/phoenix_basys3.vhd).
#
# Requires the pristine tree, already patched by
# contrib/code/phoenix_expose_hsync_vsync.patch (run `make setup` first).
# Per project rules this script runs from /tmp so scratch stays outside the repo.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SRC="$ROOT/vhdl_phoenix_DE10_lite/rtl_dar/phoenix_de10_lite.vhd"
PROJ_DIR="$ROOT/vhdl_phoenix_DE10_lite/basys3"
TARGET_SRC="$PROJ_DIR/phoenix_basys3.srcs/sources_1/new"
PATCH="$ROOT/contrib/basys3/code/phoenix_de10_lite_to_basys3.patch"

WORK=/tmp/phoenix_de10_to_basys3
TARGET="$WORK/phoenix_basys3.vhd"

if [ ! -f "$SRC" ]; then
    echo "error: pristine source not found: $SRC" >&2
    echo "Run 'make setup' first to populate vhdl_phoenix_DE10_lite/." >&2
    exit 1
fi

rm -rf "$WORK"
mkdir -p "$WORK"

cat > "$TARGET" <<'EOF'
---------------------------------------------------------------------------------
-- Basys3 Top level for Phoenix (Amstar, 1980) by Dar (darfpga@aol.fr) (30/01/2025)
-- http://darfpga.blogspot.fr
--
-- Basys3 port by Red~Bote.
--
-- Ported from phoenix_de10_lite.vhd (DE10-lite rev 30/01/2025):
--  - 100 MHz board oscillator, clk_wiz_0 MMCM derives 11 MHz (clock_11, core
--    + pixel clock) and 50 MHz (clock_50, fed straight to the core's sound
--    effect/music blocks exactly like the pristine top's board oscillator)
--  - The pristine phoenix core (rtl_dar/phoenix.vhd) exposed ONLY composite
--    sync (video_csync) -- no separate hsync/vsync existed anywhere in the
--    upstream design (see contrib/basys3/PORTING_SPEC.md). A first
--    implementation attempt worked around this with a duration-threshold
--    sync separator inferring hs/vs from video_csync in this wrapper;
--    hardware bring-up confirmed sound and PS/2 keyboard working (core,
--    clocking, reset all correct) but produced no VGA display. This wrapper
--    now instead uses contrib/code/phoenix_expose_hsync_vsync.patch, which
--    exposes real, separately-generated video_hs/video_vs from the core
--    (derived from its already-internal pulse_a/vblank_n signals -- no
--    threshold-guessing),
--    fed directly into the MiST scandoubler for 31 kHz VGA, exactly like
--    Burnin-Rubber/Galaga's native hs/vs wiring. Hardware bring-up confirmed
--    this works (VGA display now appears).
--  - Display mode via sw(13): 0 = 31 kHz progressive VGA (scandoubler,
--    fed by the core's real hs/vs above), 1 = 15 kHz TV (video_csync
--    straight onto vgaHsync, vgaVsync held high, native RGB passed through)
--    -- this branch exactly reproduces the pristine DE10-lite top's own
--    output path.
--  - The pristine phoenix entity accepts only a PS/2 keyboard scancode
--    stream (no coin/start/button ports exist on it at all). A patch
--    (contrib/code/phoenix_expose_control_ports.patch) adding external
--    coin/start/fire/direction ports, OR-merged internally with the PS/2
--    path and driven from the wrapper's JA joystick + dedicated buttons,
--    was tried and hardware-tested: no input registered at all (PS/2
--    keyboard, sound, and video were all confirmed working on the same
--    build). A repo-wide precedent search found Phoenix is the only core
--    in this project with PS/2 decode inside the core and no native
--    discrete-input ports, and that patch was the only one anywhere in the
--    repo adding discrete control-input ports to a pristine core -- no
--    comparable, validated implementation exists to debug against or copy
--    (see contrib/basys3/PORTING_SPEC.md). The patch has been reverted;
--    this port is PS/2-keyboard only.
--  - audio_select is 3 bits on the core (100/101/110/111 solo effect1/
--    effect2/effect3/melody, else mixed); wired to sw(10 downto 8) here
--    (the pristine DE10-lite top hardcodes it to "000", i.e. always mixed).
--  - Mono PWM audio on PmodAMP2 (JC); sw14 = shutdown, sw15 = gain select
--    (reproduces the pristine top's 13-bit accumulator verbatim).
--  - btnC = reset (also resets the MMCM; core held in reset until MMCM
--    lock). No other buttons or JA joystick are wired (see above).
--  - No led port: the pristine top's ledr assignment is a static debug
--    pattern ("101010101"), not core-driven, so it is omitted entirely --
--    matches Bagman/Pooyan/Time-Pilot/Berzerk/Burnin-Rubber's convention.
--  - The DE10-lite 7-segment debug hex display is not ported, matching
--    every other machine (no Basys3 board in this repo carries 7-segment
--    wiring).
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity phoenix_basys3 is
port(
 clk             : in  std_logic;
 sw              : in  std_logic_vector(15 downto 0);
 btnC            : in  std_logic;  -- reset

 ps2_dat         : in  std_logic;
 ps2_clk         : in  std_logic;

 O_PMODAMP2_AIN  : out std_logic;
 O_PMODAMP2_GAIN : out std_logic;
 O_PMODAMP2_SHUTD: out std_logic;

 vgaRed   : out std_logic_vector(3 downto 0);
 vgaGreen : out std_logic_vector(3 downto 0);
 vgaBlue  : out std_logic_vector(3 downto 0);
 vgaHsync : out std_logic;
 vgaVsync : out std_logic
);
end phoenix_basys3;

architecture struct of phoenix_basys3 is

 component scandoubler
     port (
         clk_sys   : in  std_logic;
         scanlines : in  std_logic_vector (1 downto 0);
         ce_x1     : in  std_logic;
         ce_x2     : in  std_logic;
         hs_in     : in  std_logic;
         vs_in     : in  std_logic;
         r_in      : in  std_logic_vector (5 downto 0);
         g_in      : in  std_logic_vector (5 downto 0);
         b_in      : in  std_logic_vector (5 downto 0);
         hs_out    : out std_logic;
         vs_out    : out std_logic;
         r_out     : out std_logic_vector (5 downto 0);
         g_out     : out std_logic_vector (5 downto 0);
         b_out     : out std_logic_vector (5 downto 0)
     );
 end component;

 signal clock_11    : std_logic;
 signal clock_50    : std_logic;
 signal mmcm_locked : std_logic;
 signal reset       : std_logic;

 signal r         : std_logic_vector(1 downto 0);
 signal g         : std_logic_vector(1 downto 0);
 signal b         : std_logic_vector(1 downto 0);
 signal video_clk : std_logic;
 signal csync     : std_logic;

 -- Real hsync/vsync from the core (contrib/code/phoenix_expose_hsync_vsync.patch)
 -- -- direct connections, no separator needed.
 signal hs, vs : std_logic;

 signal vga_r_i, vga_g_i, vga_b_i : std_logic_vector(5 downto 0);
 signal vga_r_o, vga_g_o, vga_b_o : std_logic_vector(5 downto 0);
 signal hsync_o, vsync_o          : std_logic;

 signal audio           : std_logic_vector(11 downto 0);
 signal pwm_accumulator : std_logic_vector(12 downto 0);

begin

 -- btnC is active-high: it resets the MMCM and, together with !locked,
 -- holds the core in reset until the clock is stable.
 reset <= btnC or not mmcm_locked;

 clocks : entity work.clk_wiz_0
 port map(
  clk_in1  => clk,
  clk_out1 => clock_11,
  clk_out2 => clock_50,
  reset    => btnC,
  locked   => mmcm_locked
 );

 -- Phoenix
 phoenix_inst : entity work.phoenix
 port map(
  clock_50     => clock_50,
  clock_11     => clock_11,
  reset        => reset,
  dip_switch   => sw(7 downto 0),
  ps2_clk      => ps2_clk,
  ps2_dat      => ps2_dat,
  video_r      => r,
  video_g      => g,
  video_b      => b,
  video_clk    => video_clk,
  video_csync  => csync,
  video_hs     => hs,
  video_vs     => vs,
  audio_select => sw(10 downto 8),
  audio        => audio
 );

 -- Pad native 2-bit/channel RGB to the scan doubler's 6-bit/channel input
 -- by triple replication. No external blanking gate is needed: the core
 -- already forces video_r/g/b to "00" internally during hblank/vblank (see
 -- PORTING_SPEC.md) -- the pristine DE10-lite top relies on the same thing
 -- (its blankn is tied constant true).
 vga_r_i <= r & r & r;
 vga_g_i <= g & g & g;
 vga_b_i <= b & b & b;

 scandoubler_inst : scandoubler
 port map (
   clk_sys   => clock_11,
   scanlines => "00",
   ce_x1     => video_clk,
   ce_x2     => '1',
   hs_in     => hs,
   vs_in     => vs,
   r_in      => vga_r_i,
   g_in      => vga_g_i,
   b_in      => vga_b_i,
   hs_out    => hsync_o,
   vs_out    => vsync_o,
   r_out     => vga_r_o,
   g_out     => vga_g_o,
   b_out     => vga_b_o
 );

 -- Display mode switch via sw(13):
 --   0 = 31 kHz VGA (scan-doubled, top 4 bits of each 6-bit channel)
 --   1 = 15 kHz TV  (native core rate, composite sync on HS, VS held high
 --       -- requires a 15 kHz RGB monitor or RGB->composite converter;
 --       reproduces the pristine DE10-lite top's own output exactly)
 vgaHsync <= hsync_o             when sw(13) = '0' else csync;
 vgaVsync <= vsync_o             when sw(13) = '0' else '1';
 vgaRed   <= vga_r_o(5 downto 2) when sw(13) = '0' else r & "00";
 vgaGreen <= vga_g_o(5 downto 2) when sw(13) = '0' else g & "00";
 vgaBlue  <= vga_b_o(5 downto 2) when sw(13) = '0' else b & "00";

 -- pwm sound output (reproduces the pristine top's exact accumulator,
 -- clocked on clock_11 -- "use same clock as pooyan_sound_board").
 process(clock_11)
 begin
   if rising_edge(clock_11) then
     pwm_accumulator <= std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned(audio & '0'));
   end if;
 end process;

 O_PMODAMP2_AIN   <= pwm_accumulator(12);
 O_PMODAMP2_SHUTD <= sw(14);  -- shutdown: 0 = off, 1 = on
 O_PMODAMP2_GAIN  <= sw(15);  -- gain: 0 = 12 dB, 1 = 6 dB

end struct;
EOF

# Emit git-style patch (matches the *_de10_lite_to_basys3.patch convention).
mkdir -p "$(dirname "$PATCH")"
{
  printf 'diff --git a/vhdl_phoenix_DE10_lite/rtl_dar/phoenix_de10_lite.vhd b/vhdl_phoenix_DE10_lite/rtl_dar/phoenix_de10_lite.vhd\n'
  diff -u --label "a/vhdl_phoenix_DE10_lite/rtl_dar/phoenix_de10_lite.vhd" \
            --label "b/vhdl_phoenix_DE10_lite/rtl_dar/phoenix_de10_lite.vhd" \
            "$SRC" "$TARGET" || [ $? -eq 1 ]   # diff returns 1 when files differ (expected)
} > "$PATCH"

mkdir -p "$TARGET_SRC"
cp -f "$TARGET" "$TARGET_SRC/phoenix_basys3.vhd"

rm -rf "$WORK"

echo "Generated patch:  $PATCH"
echo "Placed target:    $TARGET_SRC/phoenix_basys3.vhd"
echo "Verify with:      patch -p1 --dry-run < contrib/basys3/code/phoenix_de10_lite_to_basys3.patch"
