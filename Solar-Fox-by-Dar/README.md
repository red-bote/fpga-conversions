# Solar-Fox-by-Dar (Basys 3 port)

Solar Fox (Bally Midway, 1981) by Dar (`darfpga@aol.fr`,
http://darfpga.blogspot.fr). Basys 3 (Artix-7) port by Red~Bote. See
`readme-dar.txt` for the original Dar release notes.

- Vivado 2020.2 project: `basys3/solarfox_basys3.xpr` (top entity
  `solarfox_basys3`)
- Core clock: 40 MHz (from the 100 MHz Basys 3 oscillator via `clk_wiz_0`)

## Features supported

- **Video**: 31 kHz progressive VGA (scan doubling built into the core);
  **F8** toggles 31 kHz VGA / 15 kHz TV.
- **Sound**: stereo L/R PWM audio path in the core; PmodAMP2 `AIN` is driven
  from the left channel. **F5** toggles separate (stereo) audio mode, **F7**
  toggles service mode.
- **Controls**: PS/2 keyboard + JA joystick (OR-merged, verified working),
  btnC = reset.

| Input | Keyboard |
|-------|----------|
| Move | Arrow keys |
| Fire | Space |
| Coin | F1 |
| Fast | F2 |
| Separate audio (stereo/mono) | F5 |
| Service | F7 |

JA joystick (active-low, switch to GND):
- JA1 = Right, JA2 = Left, JA3 = Down, JA4 = Up, JA7 = Fire
- Coin = Fire + Up together; Fast = Fire + Left together

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

MAME ROM set `solarfox.zip`, unzipped into `tools/solar_fox_unzip/`:

```
~/roms/solarfox.zip   ->   tools/solar_fox_unzip/
```

Then run `./make_solar_fox_proms.sh` from that directory to generate the PROM
VHDL (`solar_fox_cpu.vhd`, `solar_fox_sound_cpu.vhd`, `solar_fox_bg_bits_1/2.vhd`,
`solar_fox_sp_bits.vhd`, `midssio_82s123.vhd`). Note the script concatenates
the individual chip ROMs (`sfcpu.*`, `sfsnd.*`, `sfvid.*`) into
`solar_fox_cpu.bin` / `solar_fox_sound_cpu.bin` / `solar_fox_sp_bits.bin`
before conversion, and `82s123.12d` is the same color PROM as Kick's. The
Vivado project references these generated files in place, so the build needs
only the staged ROMs + the script.

Game ROMs are copyrighted — never commit or redistribute them.
