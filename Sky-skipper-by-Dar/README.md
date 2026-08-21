# Sky-skipper-by-Dar (Basys 3 port)

Sky Skipper (Nintendo, 1981) by Dar (`darfpga@aol.fr`,
http://darfpga.blogspot.fr). Basys 3 (Artix-7) port by Red~Bote. See
`README.txt` in the extracted source archive for the original Dar release
notes.

- Vivado 2020.2 project: `basys3/sky_skipper_basys3.xpr` (top entity
  `sky_skipper_basys3`)
- Core clock: 40 MHz (from the 100 MHz Basys 3 oscillator via `clk_wiz_0`)
- `clk_wiz_0` Clocking Wizard (MMCM, 100 MHz in): `clk_out1` = 40.000 MHz;
  reset active-high (btnC), `locked` used. Solved MMCM: `DIVCLK_DIVIDE=1`,
  `CLKFBOUT_MULT_F=10.0`, `CLKOUT0_DIVIDE_F=25.0`.

## Features supported

- **Video**: 31 kHz progressive VGA (scan doubling built into the core);
  **F8** toggles 31 kHz VGA / 15 kHz TV.
- **Sound**: mono PWM audio on PmodAMP2.
- **Controls**: PS/2 keyboard + JA joystick (OR-merged), btnC = reset.

| Input | Keyboard |
|-------|----------|
| Move | Arrow keys |
| Fire A | Space |
| Fire B | F |
| Coin 1 | F1 |
| Coin 2 | F2 |
| Start 1 | F3 |
| Start 2 | F4 |
| Service | F7 |

JA joystick (active-low, switch to GND):
- JA1 = Right, JA2 = Left, JA3 = Down, JA4 = Up, JA7 = Fire (both Fire A and Fire B)
- Coin = Fire + Up together; Start = Fire + Left together

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
| LEDs | `led(15:0)` | present |

## Scripted setup

`contrib/tools/setup_sky_skipper.sh` automates the manual steps below: it
fetches the Dar archive into the gitignored `dloads/` cache (reused when its
SHA-256 matches the hash embedded in the script; re-downloaded when missing or
tampered), extracts it as `vhdl_sky_skipper_rev_01_2020_01_28/`, then runs
`contrib/tools/prep_roms.sh` to compile `make_vhdl_prom`, convert
`make_sky_skipper_proms.bat`, stage the romset from `$ROMZIP` (default
`~/roms/skyskipr.zip`) and generate the PROM VHDL. Run it via `make setup`.

## ROM set required

MAME ROM set `skyskipr.zip`, unzipped into `tools/sky_skipper_unzip/`:

```
~/roms/skyskipr.zip   ->   tools/sky_skipper_unzip/
```

Then run `./make_sky_skipper_proms.sh` from that directory to generate the PROM
VHDL (`sky_skipper_cpu.vhd`, `sky_skipper_ch_bits.vhd`,
`sky_skipper_sp_bits_1..4.vhd`, `sky_skipper_ch_palette_rgb.vhd`,
`sky_skipper_sp_palette_gb.vhd`, `sky_skipper_sp_palette_rg.vhd`,
`sky_skipper_bg_palette_rgb.vhd`). The Vivado project references these
generated files in place, so the build needs only the staged ROMs + the script.

machine ROMs are copyrighted — never commit or redistribute them.
