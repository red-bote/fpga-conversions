# Kick-Midway-MCR-by-Dar (Basys 3 port)

Kick (Midway MCR, 1981) by Dar (`darfpga@aol.fr`,
http://darfpga.blogspot.fr). Basys 3 (Artix-7) port by Red~Bote. See
`readme-dar.txt` for the original Dar release notes.

- Vivado 2020.2 project: `basys3/kickman_basys.xpr` (top entity
  `kickman_basys3`; note the project dir has no trailing `3`)
- Core clock: 40 MHz (from the 100 MHz Basys 3 oscillator via `clk_wiz_0`)
- `clk_wiz_0` Clocking Wizard (MMCM, 100 MHz in): `clk_out1` = 40.000 MHz;
  reset active-high (btnC), `locked` used. Solved MMCM: `DIVCLK_DIVIDE=1`,
  `CLKFBOUT_MULT_F=10.0`, `CLKOUT0_DIVIDE_F=25.0`.

## Features supported

- **Video**: 31 kHz progressive VGA (scan doubling built into the core);
  **F8** toggles 31 kHz VGA / 15 kHz TV.
- **Sound**: stereo L/R PWM audio path in the core; PmodAMP2 `AIN` is driven
  from the left channel. **F5** toggles separate (stereo) audio mode, **F7**
  toggles service mode.
- **Controls**: PS/2 keyboard + JA joystick (OR-merged), btnC = reset.

| Input | Keyboard |
|-------|----------|
| Kick | Up arrow |
| Spin left / right | Left / Right arrow |
| Speed up | Space |
| Coin | F1 |
| Start 1 | F2 |
| Start 2 | F3 |
| Separate audio (stereo/mono) | F5 |
| Service | F7 |

JA joystick (active-low, switch to GND):
- JA1 = Spin right, JA2 = Spin left, JA3 = Down, JA4 = Up (kick), JA7 = Fire (speed up)
- Coin = Fire + Up together; Start 1 = Fire + Left together

## IO mapping

| Basys 3 resource | Wrapper port | Function |
|------------------|--------------|----------|
| clk (W5, 100 MHz) | `clk` | clock into `clk_wiz_0` MMCM |
| btnC | `btnC` | reset (active-high) |
| btnU/btnL/btnR/btnD | `btnU/L/R/D` | declared, unused (reserved) |
| sw(15) | `O_PMODAMP2_GAIN` | AMP gain: 0 = 12 dB, 1 = 6 dB |
| sw(14) | `O_PMODAMP2_SHUTD` | AMP shutdown: 0 = off, 1 = on |
| JB1 / JB3 | `ps2_dat` (JB(0)) / `ps2_clk` (JB(2)) | PS/2 keyboard |
| JA1-JA4, JA7 | `JA(0..4)` | joystick (active-low) |
| JC (PmodAMP2) | `O_PMODAMP2_AIN` | PWM audio (left channel) |
| VGA | `vgaRed/vgaGreen/vgaBlue(3:0)`, `vgaHsync`, `vgaVsync` | 4-4-4 RGB, 31 kHz |
| LEDs | `led(15:0)` | present |

## ROM set required

MAME ROM set `kick.zip`, unzipped into `tools/kick_unzip/`:

```
~/roms/kick.zip   ->   tools/kick_unzip/
```

Then run `./make_kick_proms.sh` from that directory to generate the PROM VHDL
(`kick_cpu.vhd`, `kick_sound_cpu.vhd`, `kick_bg_bits_1/2.vhd`,
`kick_sp_bits.vhd`, `midssio_82s123.vhd`). Note the script concatenates the
individual chip ROMs (`1200a`-`1900h`, etc.) into `kick_cpu.bin` /
`kick_sound_cpu.bin` / `kick_sp_bits.bin` before conversion. The Vivado project
references these generated files in place, so the build needs only the staged
ROMs + the script.

Game ROMs are copyrighted — never commit or redistribute them.
