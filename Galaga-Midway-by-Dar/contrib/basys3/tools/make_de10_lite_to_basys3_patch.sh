#!/bin/bash
# Generate the patch that adapts the upstream DE10-lite top level
# (rtl_dar/galaga_de10_lite.vhd) into the Basys3 top level (galaga_basys3.vhd).
#
# The target galaga_basys3.vhd is authored here (it is a full rewrite of the
# top-level wrapper). The script:
#   1. Writes the target VHDL to a scratch dir.
#   2. Diffs it against the pristine upstream source to produce the git-style
#      patch at contrib/basys3/code/galaga_de10_lite_to_basys3.patch.
#   3. Places the target where galaga_basys3.xpr expects it
#      (basys3/galaga_basys3.srcs/sources_1/new/galaga_basys3.vhd).
#
# Requires the pristine tree (run `make setup` first).
# Per project rules this script runs from /tmp so scratch stays outside the repo.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CONTRIB="$ROOT/contrib/basys3"
SRC="$ROOT/vhdl_galaga_rev_0_3_2018_05_06/rtl_dar/galaga_de10_lite.vhd"
PROJ_DIR="$ROOT/vhdl_galaga_rev_0_3_2018_05_06/basys3"
TARGET_SRC="$PROJ_DIR/galaga_basys3.srcs/sources_1/new"
PATCH="$CONTRIB/code/galaga_de10_lite_to_basys3.patch"

WORK=/tmp/galaga_de10_to_basys3
TARGET="$WORK/galaga_basys3.vhd"

if [ ! -f "$SRC" ]; then
    echo "error: pristine source not found: $SRC" >&2
    echo "Run 'make setup' first to populate vhdl_galaga_rev_0_3_2018_05_06/." >&2
    exit 1
fi

rm -rf "$WORK"
mkdir -p "$WORK"

cat > "$TARGET" <<'EOF'
---------------------------------------------------------------------------------
-- Basys3 Top level for Galaga Midway by Dar (darfpga@aol.fr) (06/11/2017)
-- http://darfpga.blogspot.fr
--
-- Basys3 port by Red~Bote.
--
-- Ported from galaga_de10_lite.vhd (DE10-lite rev 03 06/05/2018):
--  - 100 MHz board oscillator, clk_wiz_0 MMCM derives 36 MHz core clock
--  - Atari-style joystick on JA, OR-merged with PS/2 keyboard (JB)
--  - Mono PWM audio on PmodAMP2 (JC); sw14 = shutdown, sw15 = gain select
--  - 31 kHz VGA on the Basys3 VGA connector via the MiST scandoubler
--  - btnC = reset
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;

entity galaga_basys3 is
port(
 clk            : in  std_logic;
 sw             : in  std_logic_vector(15 downto 0);
 btnC           : in  std_logic;

 JA             : in  std_logic_vector(4 downto 0);  -- joystick
 ps2_dat        : in  std_logic;
 ps2_clk        : in  std_logic;

 O_PMODAMP2_AIN : out std_logic;
 O_PMODAMP2_GAIN: out std_logic;
 O_PMODAMP2_SHUTD: out std_logic;

 vga_r : out std_logic_vector(3 downto 0);
 vga_g : out std_logic_vector(3 downto 0);
 vga_b : out std_logic_vector(3 downto 0);
 vga_hs: out std_logic;
 vga_vs: out std_logic
);
end galaga_basys3;

architecture struct of galaga_basys3 is

 signal clock_36 : std_logic;
 signal reset    : std_logic;
 signal clock_18 : std_logic;
 signal clock_12 : std_logic;
 signal clock_6  : std_logic;
 signal slot     : unsigned(2 downto 0);

 signal r        : std_logic_vector(2 downto 0);
 signal g        : std_logic_vector(2 downto 0);
 signal b        : std_logic_vector(1 downto 0);
 signal csync    : std_logic;
 signal blankn   : std_logic;

 signal audio           : std_logic_vector( 9 downto 0);
 signal pwm_accumulator : std_logic_vector(12 downto 0);

 signal vga_ro    : std_logic_vector(5 downto 0);
 signal vga_go    : std_logic_vector(5 downto 0);
 signal vga_bo    : std_logic_vector(5 downto 0);
 signal vga_hs_o  : std_logic;
 signal vga_vs_o  : std_logic;

 signal video_ri : std_logic_vector(5 downto 0);
 signal video_gi : std_logic_vector(5 downto 0);
 signal video_bi : std_logic_vector(5 downto 0);

 signal scanlines       : std_logic_vector(1 downto 0);

 signal kbd_intr      : std_logic;
 signal kbd_scancode  : std_logic_vector(7 downto 0);
 signal kbd_joy       : std_logic_vector(7 downto 0);
 signal joyPCFRLDU    : std_logic_vector(7 downto 0);

begin

reset <= btnC;

-- Clock 36MHz for galaga core (from 100 MHz)
clocks : entity work.clk_wiz_0
port map(
 clk_in1  => clk,
 clk_out1 => clock_36,
 locked   => open
);

-- Derive core clock_18 (18 MHz), scandoubler clk_sys clock_12 (12 MHz), and
-- ce_x1 clock_6 (6 MHz) from the 36 MHz PLL output via a 6-slot counter.
process (reset, clock_36)
begin
	if reset='1' then
		slot     <= (others => '0');
		clock_18 <= '0';
		clock_12 <= '0';
		clock_6  <= '0';
	else
		if rising_edge(clock_36) then
			if slot = 5 then slot <= (others => '0'); else slot <= slot + 1; end if;
			if slot(0) = '1' then clock_18 <= not clock_18; end if;            -- toggle every 2 slots -> 18 MHz
			if slot = 2 or slot = 5 then clock_12 <= not clock_12; end if;     -- toggle every 3 slots -> 12 MHz
			if slot = 5 then clock_6  <= not clock_6;  end if;                 -- toggle every 6 slots -> 6 MHz
		end if;
	end if;
end process;

-- Galaga
galaga : entity work.galaga
port map(
 clock_18     => clock_18,
 reset        => reset,

 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_clk    => open,
 video_csync  => csync,
 video_blankn => blankn,
 video_hs     => vga_hs_o,
 video_vs     => vga_vs_o,
 audio        => audio,

 b_test       => '1',
 b_svce       => '1',
 coin         => joyPCFRLDU(7),
 start1       => joyPCFRLDU(5),
 left1        => joyPCFRLDU(2),
 right1       => joyPCFRLDU(3),
 fire1        => joyPCFRLDU(4),
 start2       => joyPCFRLDU(6),
 left2        => joyPCFRLDU(2),
 right2       => joyPCFRLDU(3),
 fire2        => joyPCFRLDU(4)
);

-- 31 kHz VGA via the MiST scandoubler (canonical import, never modify)
-- Verified clocks (see SCANDOUBLER_CLOCK_SPEC.md): clk_sys = clock_12,
-- ce_x1 = clock_6, ce_x2 = '1' (ratio 12/6 = 2). clock_18 / clock_36 / video_clk
-- as clk_sys do NOT work.
-- The core's separate hsync/vsync (exposed by galaga_vga_sync.patch) are wired
-- directly to the doubler, active-low; the doubler re-times hsync for VGA.
-- RGB is gated on blankn; Galaga outputs 3/3/2 bits/color, padded to 6-bit.
video_ri <= (r & "000") when blankn = '1' else "000000";
video_gi <= (g & "000") when blankn = '1' else "000000";
video_bi <= (b & "0000") when blankn = '1' else "000000";

scanlines <= "00";

scandoubler : entity work.scandoubler
port map(
 clk_sys    => clock_12,
 scanlines  => scanlines,
 ce_x1      => clock_6,
 ce_x2      => std_logic'('1'),
 hs_in      => vga_hs_o,
 vs_in      => vga_vs_o,
 r_in       => video_ri,
 g_in       => video_gi,
 b_in       => video_bi,
 hs_out     => vga_hs,
 vs_out     => vga_vs,
 r_out      => vga_ro,
 g_out      => vga_go,
 b_out      => vga_bo
);

-- adapt 6-bit scan-doubled output to 4bits/color
vga_r <= vga_ro(5 downto 2);
vga_g <= vga_go(5 downto 2);
vga_b <= vga_bo(5 downto 2);

-- get scancode from keyboard
keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_18, -- synchrounous clock with core
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- translate scancode to joystick
joystick : entity work.kbd_joystick
port map (
  clk           => clock_18, -- synchrounous clock with core
  kbdint        => kbd_intr,
  kbdscancode   => std_logic_vector(kbd_scancode),
  joyPCFRLDU    => kbd_joy
);

-- OR-merge the Atari-style joystick on JA with the PS/2 keyboard joystick.
-- JA physical map (matches the sibling ports): JA1=right, JA2=left, JA3=down, JA4=up, JA7=fire,
-- i.e. JA(0)=right, JA(1)=left, JA(2)=down, JA(3)=up, JA(4)=fire.
-- JA is active-low (pressed shorts to ground); invert so a press reads active-high, matching the
-- core's active-high input boundary and the keyboard path.
-- Coin/start are reachable from the joystick via fire+direction combos, OR-merged with keyboard.
joyPCFRLDU(0) <= kbd_joy(0) or not JA(3);                 -- up    (JA4)
joyPCFRLDU(1) <= kbd_joy(1) or not JA(2);                 -- down  (JA3)
joyPCFRLDU(2) <= kbd_joy(2) or not JA(1);                 -- left  (JA2)
joyPCFRLDU(3) <= kbd_joy(3) or not JA(0);                 -- right (JA1)
joyPCFRLDU(4) <= kbd_joy(4) or not JA(4);                 -- fire  (JA7)
joyPCFRLDU(5) <= kbd_joy(5) or (not JA(4) and not JA(1)); -- start1 = fire+left
joyPCFRLDU(6) <= kbd_joy(6) or (not JA(4) and not JA(0)); -- start2 = fire+right
joyPCFRLDU(7) <= kbd_joy(7) or (not JA(4) and not JA(3)); -- coin   = fire+up

-- pwm sound output
process(clock_18)
begin
  if rising_edge(clock_18) then
    pwm_accumulator  <=  std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned('0' & audio & '0'));
  end if;
end process;

O_PMODAMP2_AIN   <= pwm_accumulator(12);
O_PMODAMP2_SHUTD <= sw(14);  -- shutdown: 0 = off, 1 = on
O_PMODAMP2_GAIN  <= sw(15);  -- gain: 0 = 12 dB, 1 = 6 dB

end struct;
EOF

# Emit git-style patch (matches the pooyan/time_pilot_de10_lite_to_basys3.patch convention).
{
  printf 'diff --git a/vhdl_galaga_rev_0_3_2018_05_06/rtl_dar/galaga_de10_lite.vhd b/vhdl_galaga_rev_0_3_2018_05_06/rtl_dar/galaga_de10_lite.vhd\n'
  diff -u --label "a/vhdl_galaga_rev_0_3_2018_05_06/rtl_dar/galaga_de10_lite.vhd" \
            --label "b/vhdl_galaga_rev_0_3_2018_05_06/rtl_dar/galaga_de10_lite.vhd" \
            "$SRC" "$TARGET" || [ $? -eq 1 ]   # diff returns 1 when files differ (expected)
} > "$PATCH"

mkdir -p "$TARGET_SRC"
cp -f "$TARGET" "$TARGET_SRC/galaga_basys3.vhd"

rm -rf "$WORK"

echo "Generated patch:  $PATCH"
echo "Placed target:    $TARGET_SRC/galaga_basys3.vhd"
echo "Verify with:      patch -p1 --dry-run < contrib/basys3/code/galaga_de10_lite_to_basys3.patch"