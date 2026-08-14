---------------------------------------------------------------------------------
-- Pooyan Basys 3 port by Red~Bote, for the Dar pooyan core (darfpga@aol.fr)
-- http://darfpga.blogspot.fr
--
-- Basys 3 (Artix-7, xc7a35tcpg236-1) top wrapper, regenerated on every run by
-- contrib/basys3/create_project.sh from the IO mapping + Wiring facts tables in
-- Pooyan-by-Dar/README.md (source of truth). Do not hand-edit; change the README.
--
-- Clocks  : 100.000 MHz -> clk_wiz_0 MMCM -> clock_12 (12.288 MHz, game core)
--           + clock_14 (14.318 MHz, sound board)
-- Video   : 31 kHz progressive VGA via the DECA vga_scandoubler.v cleanroom import;
--           clkvga = clock_12, clkvideo = clock_6 (half-rate)
-- Controls: PS/2 keyboard on JB1/JB3 + JA joystick (active-low, OR-merged),
--           btnC = reset (active-high)
-- Audio   : PWM on PmodAMP2 (JC1=AIN); sw(15)/sw(14) select amp gain/shutdown
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity pooyan_basys3 is
port(
 clk                : in  std_logic;
 btnC               : in  std_logic;
 sw                 : in  std_logic_vector(15 downto 0);
 ps2_dat            : in  std_logic;
 ps2_clk            : in  std_logic;
 JA                 : in  std_logic_vector(4 downto 0);
 O_PMODAMP2_AIN     : out std_logic;
 O_PMODAMP2_GAIN    : out std_logic;
 O_PMODAMP2_SHUTD   : out std_logic;
 vga_r              : out std_logic_vector(3 downto 0);
 vga_g              : out std_logic_vector(3 downto 0);
 vga_b              : out std_logic_vector(3 downto 0);
 vga_hs             : out std_logic;
 vga_vs             : out std_logic
);
end pooyan_basys3;

architecture struct of pooyan_basys3 is

 signal clock_12 : std_logic;
 signal clock_14 : std_logic;
 signal clock_6 : std_logic;
 signal reset    : std_logic;
 signal pll_locked : std_logic;

 signal r      : std_logic_vector(2 downto 0);
 signal g      : std_logic_vector(2 downto 0);
 signal b      : std_logic_vector(1 downto 0);
 signal csync  : std_logic;
 signal hsync  : std_logic;
 signal vsync  : std_logic;
 signal blankn : std_logic;

 signal r6, g6, b6    : std_logic_vector(5 downto 0);
 signal r6o, g6o, b6o : std_logic_vector(5 downto 0);

 signal audio           : std_logic_vector(10 downto 0);
 signal pwm_accumulator : std_logic_vector(12 downto 0);

 signal kbd_intr     : std_logic;
 signal kbd_scancode : std_logic_vector(7 downto 0);
 signal kbd_joy      : std_logic_vector(7 downto 0);
 signal joyPCFRLDU   : std_logic_vector(7 downto 0);

begin

 reset <= btnC;

 O_PMODAMP2_GAIN  <= sw(15);
 O_PMODAMP2_SHUTD <= sw(14);

 -- 100.000 MHz -> clock_12 (12.288 MHz, game core) + clock_14 (14.318 MHz, sound)
 clk_wiz_0 : entity work.clk_wiz_0
 port map(
  clk_in1  => clk,
  clk_out1 => clock_12,
  clk_out2 => clock_14,
  locked   => pll_locked
 );

 -- Pooyan core (untouched Dar RTL). video_clk is declared on the core entity
 -- but never driven - leave it unconnected (see README).
 pooyan : entity work.pooyan
 port map(
  clock_12     => clock_12,
  clock_14     => clock_14,
  reset        => reset,
  video_r      => r,
  video_g      => g,
  video_b      => b,
  video_clk    => open,
  video_csync  => csync,
  video_blankn => blankn,
  video_hs     => hsync,
  video_vs     => vsync,
  audio_out    => audio,
  dip_switch_1 => X"FF", -- Coinage_B / Coinage_A
  dip_switch_2 => X"7F", -- Sound(8)/Difficulty(7-5)/Bonus(4)/Cocktail(3)/lives(2-1)
  start2       => joyPCFRLDU(7),
  start1       => joyPCFRLDU(6),
  coin1        => joyPCFRLDU(5),
  fire1        => joyPCFRLDU(4),
  right1       => joyPCFRLDU(3),
  left1        => joyPCFRLDU(2),
  down1        => joyPCFRLDU(1),
  up1          => joyPCFRLDU(0),
  fire2        => joyPCFRLDU(4),
  right2       => joyPCFRLDU(3),
  left2        => joyPCFRLDU(2),
  down2        => joyPCFRLDU(1),
  up2          => joyPCFRLDU(0),
  dbg_cpu_addr => open
 );

 -- widen 3:3:2 core RGB to 6:6:6 for the scandoubler
 r6 <= r & r when blankn = '1' else "000000"; -- RB: I had to add the when blankn condition manually
 g6 <= g & g when blankn = '1' else "000000"; -- RB: I had to add the when blankn condition manually
 b6 <= b & b & b when blankn = '1' else "000000"; -- RB: I had to add the when blankn condition manually

 -- DECA scandoubler: 15 kHz composite-sync video -> 31 kHz progressive VGA.
 -- enable_scandoubling = '1' (the 15 kHz bypass is not wired on this port).
 scandoubler : entity work.vga_scandoubler
 port map(
  clkvideo            => clock_6,
  clkvga              => clock_12,
  enable_scandoubling => std_logic'('1'),
  disable_scaneffect  => std_logic'('1'),
  ri                  => r6,
  gi                  => g6,
  bi                  => b6,
  hsync_ext_n         => hsync,
  vsync_ext_n         => vsync,
  csync_ext_n         => csync,
  ro                  => r6o,
  go                  => g6o,
  bo                  => b6o,
  hsync               => vga_hs,
  vsync               => vga_vs
 );

 -- truncate 6:6:6 to 4:4:4 for the Basys 3 VGA connector
 vga_r   <= r6o(5 downto 2);
 vga_g <= g6o(5 downto 2);
 vga_b  <= b6o(5 downto 2);

 -- keyboard/joystick run on clock_6 (the core's synchronous half-rate clock)
 process (reset, clock_12)
 begin
  if reset = '1' then
   clock_6 <= '0';
  elsif rising_edge(clock_12) then
   clock_6 <= not clock_6;
  end if;
 end process;

 keyboard : entity work.io_ps2_keyboard
 port map(
  clk       => clock_6,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
 );

 joystick : entity work.kbd_joystick
 port map(
  clk          => clock_6,
  kbdint       => kbd_intr,
  kbdscancode  => std_logic_vector(kbd_scancode),
  joyPCFRLDU   => kbd_joy
 );

 -- OR-merge the JA joystick (active-low, switch to GND) into the keyboard
 -- bus and decode the combo presses:
 --   JA1=right JA2=left JA3=down JA4=up JA7=fire
 --   Coin = fire+up, Start 1 = fire+left, Start 2 = fire+right
 joyPCFRLDU(0) <= kbd_joy(0) or not JA(3); -- up
 joyPCFRLDU(1) <= kbd_joy(1) or not JA(2); -- down
 joyPCFRLDU(2) <= kbd_joy(2) or not JA(1); -- left
 joyPCFRLDU(3) <= kbd_joy(3) or not JA(0); -- right
 joyPCFRLDU(4) <= kbd_joy(4) or not JA(4); -- fire
 joyPCFRLDU(5) <= kbd_joy(5) or (not JA(4) and not JA(3)); -- coin
 joyPCFRLDU(6) <= kbd_joy(6) or (not JA(4) and not JA(1)); -- start 1
 joyPCFRLDU(7) <= kbd_joy(7) or (not JA(4) and not JA(0)); -- start 2

 -- PWM audio on clock_14 (same clock as the sound board); MSB drives AIN
 process(clock_14)
 begin
  if rising_edge(clock_14) then
   pwm_accumulator <= std_logic_vector(unsigned('0' & pwm_accumulator(11 downto 0)) + unsigned(audio & "00"));
  end if;
 end process;

 O_PMODAMP2_AIN <= pwm_accumulator(12);

end struct;
