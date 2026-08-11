---------------------------------------------------------------------------------
-- Basys 3 Top level for Pooyan by Dar (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
--
-- Port of the DE10-Lite wrapper (pooyan_de10_lite.vhd) to the Digilent
-- Basys 3 (Artix-7):
--   50 MHz MAX10 osc   -> 100 MHz Basys 3 osc + clk_wiz_0 MMCM
--                        (12.288 MHz core + 14.318 MHz sound)
--   active-low key(0)  -> active-high btnC, gated on MMCM locked
--   native 15 kHz      -> DECA vga_scandoubler, 31 kHz progressive VGA
--   PS/2 on GPIO       -> JB (JB1 = ps2_dat, JB3 = ps2_clk)
--   audio PWM on GPIO  -> PmodAMP2 on JC (JC1 = AIN, JC2 = GAIN,
--                        JC4 = SHUTD; sw(15)=gain, sw(14)=shutdown)
--   JA joystick (active-low, switch to GND), OR-merged with keyboard,
--   combos: Fire+Up = Coin, Fire+Left = Start 1, Fire+Right = Start 2
--
-- Keyboard: arrows = move, SPACE = fire, F1 = coin, F2 = start 1, F3 = start 2
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

entity pooyan_basys3 is
port(
 clk         : in std_logic;                     -- 100 MHz Basys 3 oscillator (W5)
 btnC        : in std_logic;                     -- reset, active-high
 sw          : in std_logic_vector(15 downto 0); -- sw(15)=gain (0=12dB), sw(14)=shutdown (0=mute)

 ps2_dat     : in std_logic;                     -- JB1
 ps2_clk     : in std_logic;                     -- JB3

 JA          : in std_logic_vector(4 downto 0);  -- JA1=Right JA2=Left JA3=Down JA4=Up JA7=Fire

 O_PMODAMP2_AIN   : out std_logic;
 O_PMODAMP2_GAIN  : out std_logic;
 O_PMODAMP2_SHUTD : out std_logic;

 vgaRed     : out std_logic_vector(3 downto 0);
 vgaGreen   : out std_logic_vector(3 downto 0);
 vgaBlue    : out std_logic_vector(3 downto 0);
 vgaHsync   : out std_logic;
 vgaVsync   : out std_logic
);
end pooyan_basys3;

architecture struct of pooyan_basys3 is

 signal clock_12     : std_logic;
 signal clock_14     : std_logic;
 signal clock_6      : std_logic;
 signal pll_locked   : std_logic;
 signal reset        : std_logic;

 signal r         : std_logic_vector(2 downto 0);
 signal g         : std_logic_vector(2 downto 0);
 signal b         : std_logic_vector(1 downto 0);
 signal csync     : std_logic;
 signal hsync     : std_logic;
 signal vsync     : std_logic;
 signal blankn    : std_logic;

 signal audio           : std_logic_vector(10 downto 0);
 signal pwm_accumulator : std_logic_vector(12 downto 0);

 signal kbd_intr     : std_logic;
 signal kbd_scancode : std_logic_vector(7 downto 0);
 signal joyPCFRLDU   : std_logic_vector(7 downto 0);

 signal vga_r_i : std_logic_vector(5 downto 0);
 signal vga_g_i : std_logic_vector(5 downto 0);
 signal vga_b_i : std_logic_vector(5 downto 0);
 signal vga_r_o : std_logic_vector(5 downto 0);
 signal vga_g_o : std_logic_vector(5 downto 0);
 signal vga_b_o : std_logic_vector(5 downto 0);
 signal vga_hs_o : std_logic;
 signal vga_vs_o : std_logic;

 signal fire1  : std_logic;
 signal right1 : std_logic;
 signal left1  : std_logic;
 signal down1  : std_logic;
 signal up1    : std_logic;

 signal dbg_cpu_addr : std_logic_vector(15 downto 0);

begin

reset <= btnC or not pll_locked;

-- Clock 12.288MHz for pooyan core, 14.318MHz for sound_board
clocks : entity work.clk_wiz_0
port map(
 clk_in1  => clk,
 clk_out1 => clock_12,
 clk_out2 => clock_14,
 reset    => btnC,
 locked   => pll_locked
);

-- get scancode from keyboard
process (reset, clock_12)
begin
	if reset='1' then
		clock_6  <= '0';
	else 
		if rising_edge(clock_12) then
				clock_6  <= not clock_6;
		end if;
	end if;
end process;

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_6, -- synchrounous clock with core
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- translate scancode to joystick
joystick : entity work.kbd_joystick
port map (
  clk           => clock_6, -- synchrounous clock with core
  kbdint        => kbd_intr,
  kbdscancode   => kbd_scancode,
  joyPCFRLDU    => joyPCFRLDU
);

-- JA joystick (active-low, switch to GND), OR-merged with keyboard
right1 <= joyPCFRLDU(3) or not JA(0); -- JA1 = Right
left1  <= joyPCFRLDU(2) or not JA(1); -- JA2 = Left
down1  <= joyPCFRLDU(1) or not JA(2); -- JA3 = Down
up1    <= joyPCFRLDU(0) or not JA(3); -- JA4 = Up
fire1  <= joyPCFRLDU(4) or not JA(4); -- JA7 = Fire

-- Pooyan
pooyan : entity work.pooyan
port map(
 clock_12   => clock_12,
 clock_14   => clock_14,
 reset      => reset,

 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_clk    => open, -- declared on the core but never driven
 video_csync  => csync,
 video_blankn => blankn,
 video_hs     => hsync,
 video_vs     => vsync,
 audio_out    => audio,

 dip_switch_1 => X"FF", -- Coinage_B / Coinage_A
 dip_switch_2 => X"7F", -- Sound(8)/Difficulty(7-5)/Bonus(4)/Cocktail(3)/lives(2-1)

 start2       => joyPCFRLDU(7) or (not JA(4) and not JA(0)), -- F3 / Fire+Right
 start1       => joyPCFRLDU(6) or (not JA(4) and not JA(1)), -- F2 / Fire+Left
 coin1        => joyPCFRLDU(5) or (not JA(4) and not JA(3)), -- F1 / Fire+Up

 fire1       => fire1,
 right1      => right1,
 left1       => left1,
 down1       => down1,
 up1         => up1,

 fire2       => fire1,
 right2      => right1,
 left2       => left1,
 down2       => down1,
 up2         => up1,

 dbg_cpu_addr => dbg_cpu_addr
);

-- VGA scandoubler: widen 3:3:2 RGB to 6:6:6, gate on blankn
vga_r_i <= r & r         when blankn = '1' else "000000";
vga_g_i <= g & g         when blankn = '1' else "000000";
vga_b_i <= b & b & b     when blankn = '1' else "000000";

scandoubler : entity work.vga_scandoubler
port map(
 clkvideo            => clock_6,
 clkvga              => clock_12,  -- has to be double of clkvideo
 enable_scandoubling => std_logic'('1'),
 disable_scaneffect  => std_logic'('1'),
 ri                  => vga_r_i,
 gi                  => vga_g_i,
 bi                  => vga_b_i,
 hsync_ext_n         => hsync,
 vsync_ext_n         => vsync,
 csync_ext_n         => csync,
 ro                  => vga_r_o,
 go                  => vga_g_o,
 bo                  => vga_b_o,
 hsync               => vga_hs_o,
 vsync               => vga_vs_o
);

-- adapt video to 4bits/color only
vgaRed   <= vga_r_o(5 downto 2);
vgaGreen <= vga_g_o(5 downto 2);
vgaBlue  <= vga_b_o(5 downto 2);
vgaHsync <= vga_hs_o;
vgaVsync <= vga_vs_o;

-- pwm sound output
process(clock_14)  -- use same clock as pooyan_sound_board
begin
  if rising_edge(clock_14) then
    pwm_accumulator  <=  std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned(audio & "00"));
  end if;
end process;

O_PMODAMP2_AIN   <= pwm_accumulator(12);
O_PMODAMP2_GAIN  <= sw(15);
O_PMODAMP2_SHUTD <= sw(14);

end struct;
