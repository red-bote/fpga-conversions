# Bagman-FPGA-Dar (Basys 3 port)

Bagman (Stern, 1982) by Dar (`darfpga@aol.fr`, http://darfpga.blogspot.fr).
Basys 3 (Artix-7) port by Red~Bote. See `readme-dar.txt` for the original
Dar release notes.

- Vivado 2020.2 project: `basys3/bagman_basys3.xpr` (top entity `bagman_basys3`)
- Core clock: 12 MHz (from the 100 MHz Basys 3 oscillator via `clk_wiz_0`)
- `clk_wiz_0` Clocking Wizard (MMCM, 100 MHz in): `clk_out1` = 12.000 MHz;
  reset active-high (btnC), `locked` used. Solved MMCM: `DIVCLK_DIVIDE=5`,
  `CLKFBOUT_MULT_F=49.875`, `CLKOUT0_DIVIDE_F=83.125`.

## Features supported

- **Video**: 31 kHz progressive VGA. Scan doubling is built into the core
  (`tv15Khz_mode = '0'` fixed — no 15 kHz TV mode on this port).
- **Sound**: mono PWM audio on PmodAMP2.
- **Controls**: PS/2 keyboard + JA joystick (OR-merged), btnC = reset.

| Input | Keyboard |
|-------|----------|
| Move | Arrow keys |
| Jump | Space |
| Coin | F3 |
| Start 1 | F1 |
| Start 2 | F2 |

JA joystick (active-low, switch to GND):
- JA1 = Right, JA2 = Left, JA3 = Down, JA4 = Up, JA7 = Jump
- Coin = Fire + Up together; Start 1 = Fire + Left together
- Player 2 mirrors player 1 inputs.

## IO mapping

| Basys 3 resource | Wrapper port | Function |
|------------------|--------------|----------|
| clk (W5, 100 MHz) | `clk` | clock into `clk_wiz_0` MMCM |
| btnC | `btnC` | reset (active-high) |
| btnU/btnL/btnR/btnD | `btnU/L/R/D` | declared, unused (reserved) |
| sw(15) | `O_PMODAMP2_GAIN` | AMP gain: 0 = 12 dB, 1 = 6 dB |
| sw(14) | `O_PMODAMP2_SHUTD` | AMP shutdown: 0 = off, 1 = on |
| JB1 / JB3 | `ps2_dat` / `ps2_clk` | PS/2 keyboard |
| JA1-JA4, JA7 | `JA(0..4)` | joystick (active-low) |
| JC (PmodAMP2) | `O_PMODAMP2_AIN` | PWM audio (JC1=AIN, JC2=GAIN, JC4=SHUTD) |
| VGA | `vgaRed/vgaGreen/vgaBlue(3:0)`, `vgaHsync`, `vgaVsync` | 4-4-4 RGB, 31 kHz |
| LEDs | `led(15:0)` | present (driven 0) |

## ROM set required

MAME ROM set `bagman.zip`, unzipped into `tools/bagman_unzip/`:

```
~/roms/bagman.zip   ->   tools/bagman_unzip/
```

Then run `./make_bagman_proms.sh` from that directory to generate the PROM VHDL
(`bagman_program.vhd`, `bagman_tile_bit0/1.vhd`, `bagman_palette.vhd`,
`bagman_speech1/2.vhd`). The Vivado project references these generated files in
place, so the build needs only the staged ROMs + the script.

machine ROMs are copyrighted — never commit or redistribute them.

## Applying the XOR-width fix

The pristine Dar core (`vhdl_bagman_rev_0_1_2018_06_05/rtl_dar/bagman.vhd`)
fails Vivado synthesis on the `tile_graph_rom_addr` XORs because the
`"00000"`/`"01000"`/`"10111"`/`"11111"` literals are narrower than the left
operand. The fix left-pads them to 13 bits:

```vhdl
when "00" => tile_graph_rom_addr <= ... xor "0000000000000"; --TBA
when "01" => tile_graph_rom_addr <= ... xor "0000000001000"; --TBA
when "10" => tile_graph_rom_addr <= ... xor "0000000010111"; --TBA
when "11" => tile_graph_rom_addr <= ... xor "0000000011111"; --TBA
```

`bagman_xor_width.patch` in this directory applies that change to the
unmodified Dar source. From the `Bagman-FPGA-Dar/` directory (containing
`vhdl_bagman_rev_0_1_2018_06_05/`):

```
patch -p1 < bagman_xor_width.patch
```

Verify it took:

```
grep -n 'xor "0000000000000"' vhdl_bagman_rev_0_1_2018_06_05/rtl_dar/bagman.vhd
```

