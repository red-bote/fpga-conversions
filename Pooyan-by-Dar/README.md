# Pooyan-by-Dar (Basys 3 port)

Pooyan (Konami, 1982) by Dar (`darfpga@aol.fr`, http://darfpga.blogspot.fr).
Basys 3 (Artix-7) port by Red~Bote. See `readme-dar.txt` for the original
Dar release notes.

- Vivado 2020.2 project: `basys3/pooyan_basys3/pooyan_basys3.xpr` (top entity
  `pooyan_basys3`)
- Core clocks: 12.288 MHz (game core) + 14.318 MHz (sound) from the 100 MHz
  Basys 3 oscillator via `clk_wiz_0`
- `clk_wiz_0` Clocking Wizard (MMCM, 100 MHz in): `clk_out1` = 12.288 MHz +
  `clk_out2` = 14.318 MHz; reset active-high (btnC), `locked` used. Solved
  MMCM: `DIVCLK_DIVIDE=7`, `CLKFBOUT_MULT_F=56.125`, `CLKOUT0_DIVIDE_F=65.25`,
  `CLKOUT1_DIVIDE=56`.

## Features supported

- **Video**: 31 kHz progressive VGA via an imported DECA scandoubler
  (`imports/deca/vga_scandoubler.v`, from
  <https://github.com/DECAfpga/Arcade_Pooyan/blob/main/deca/vga_scandoubler.v>);
  `enable_scandoubling` and `disable_scaneffect` are both `1`; `clkvga` is
  `clock_12` (12.288 MHz) and `clkvideo` is `clock_6` (half-rate). 15 kHz mode
  is the scandoubler's built-in bypass (`enable_scandoubling = '0'` → `hsync <=
  csync`, RGB passthrough), matching the DE10's native output on the same VGA
  connector — not yet wired.
- Sync wiring (do NOT copy the DE10 wrapper here — it leaves `video_hs`/
  `video_vs` open and drives VGA HSYNC from `csync` directly): the core's
  `video_hs`/`video_vs`/`video_csync` (all active-low) are wired to toplevel
  `hsync`/`vsync`/`csync` signals feeding the scandoubler's
  `hsync_ext_n`/`vsync_ext_n`/`csync_ext_n` inputs, and the scandoubler's
  `hsync`/`vsync` outputs drive the toplevel `vga_hs`/`vga_vs` ports (the
  Hsync/Vsync pins in `pooyan_basys3.xdc`, generated from the Digilent
  Basys-3-Master.xdc at
  <https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc>).
- **Sound**: mono PWM audio on PmodAMP2 (JC header).
- **Controls**: PS/2 keyboard + JA joystick (OR-merged), btnC = reset.

| Input | Keyboard |
|-------|----------|
| Move | Arrow keys |
| Fire | Space |
| Coin | F1 |
| Start 1 | F2 |
| Start 2 | F3 |

JA joystick (active-low, switch to GND):
- JA1 = Right, JA2 = Left, JA3 = Down, JA4 = Up, JA7 = Fire
- Coin = Fire + Up; Start 1 = Fire + Left; Start 2 = Fire + Right
- Player 2 mirrors player 1 movement/fire inputs.

## IO mapping

| Port | Dir | Width | Pins | Function |
|------|-----|-------|------|----------|
| clk | in | 1 | W5 | clock into `clk_wiz_0` MMCM (100 MHz) |
| btnC | in | 1 | U18 | reset (active-high) |
| sw | in | 16 | V17;V16;W16;W17;W15;V15;W14;W13;V2;T3;T2;R3;W2;U1;T1;R2 | switches; sw(15)/sw(14) drive AMP gain/shutdown |
| ps2_dat | in | 1 | A14 | PS/2 keyboard data (JB1) |
| ps2_clk | in | 1 | B15 | PS/2 keyboard clock (JB3) |
| JA | in | 5 | J1;L2;J2;G2;H1 | joystick (active-low, PULLUP true) |
| O_PMODAMP2_AIN | out | 1 | K17 | PWM audio (JC1) |
| O_PMODAMP2_GAIN | out | 1 | M18 | AMP gain: 0 = 12 dB, 1 = 6 dB (JC2) |
| O_PMODAMP2_SHUTD | out | 1 | P18 | AMP shutdown: 0 = off, 1 = on (JC4) |
| vga_r | out | 4 | G19;H19;J19;N19 | VGA Red 4-bit |
| vga_g | out | 4 | J17;H17;G17;D17 | VGA Green 4-bit |
| vga_b | out | 4 | N18;L18;K18;J18 | VGA Blue 4-bit |
| vga_hs | out | 1 | P19 | VGA Hsync |
| vga_vs | out | 1 | R19 | VGA Vsync |

## Wiring facts

| Fact | Value |
|------|-------|
| clk_wiz.input | 100.000 |
| clk_wiz.out1 | 12.288 |
| clk_wiz.out2 | 14.318 |
| clk_wiz.out1_signal | clock_12 |
| clk_wiz.out2_signal | clock_14 |
| scandoubler.clkvga | clock_12 |
| scandoubler.clkvideo | clock_6 |
| kbd_clk | clock_6 |
| pwm_clk | clock_14 |
| scandoubler.rgb_width | 6 |
| rgb_vga | 4 |
| dip_switch_1 | FF |
| dip_switch_2 | 7F |
| scandoubler.enable | 1 |
| scandoubler.scaneffect | 1 |
| amp.gain_from | sw(15) |
| amp.shutdown_from | sw(14) |
| rgb_core | 3;3;2 |
| video_clk | open |
| ja.pullup | 1 |

## ROM set required

MAME ROM set `pooyan.zip`, unzipped into `tools/pooyan_unzip/`:

```
~/roms/pooyan.zip   ->   tools/pooyan_unzip/
```

Then run `./make_pooyan_proms.sh` from that directory to generate the PROM VHDL:
`pooyan_prog.vhd`, `pooyan_sound_prog.vhd`, `pooyan_char_grphx1/2.vhd`,
`pooyan_sprite_grphx1/2.vhd`, `pooyan_palette.vhd`,
`pooyan_char_color_lut.vhd`, `pooyan_sprite_color_lut.vhd`.

**Build prerequisite:** these generated files must exist before the project can
be synthesized — `pooyan.vhd` and `pooyan_sound_board.vhd` instantiate each one
by entity name, and `rtl_dar/proms/` is empty in the tree, so a build without
them fails with missing entities. The Vivado project references the generated
files in place, so the build needs only the staged ROMs + this script. The
script needs `make_vhdl_prom` rebuilt from
`tools/tools_prom_src/src/make_vhdl_prom.c` (`gcc make_vhdl_prom.c -lm`) — the
shipped `linux32` binary is a 32-bit ELF that will not run on a 64-bit host.

Game ROMs and the generated PROM VHDL are copyrighted — never commit or
redistribute them.

## Porting gotchas

- `video_clk` (`pooyan.vhd:88`) is declared on the core entity but never
  driven — leave it unconnected; do not add a wrapper port for it.
- The DE10 `.qsf` lists `rtl_dar/proms/pooyan_sprite_grphx.vhd`, but the core
  never instantiates it and the `.bat` never generates it — omit it from the
  Vivado project (it would be a missing file).
- RGB is 3:3:2 from the core (`video_r`/`video_g` 3 bits, `video_b` 2 bits).
  Widen to 6:6:6 by bit duplication (`r&r`, `g&g`, `b&b&b`) for the scandoubler,
  then truncate to 4:4:4 (`[5:2]`) for the VGA connector. Do NOT copy the DE10
  wrapper's low-bit padding (`vga_r <= r&'0'`) — that is only for the direct
  15 kHz path.
- `pooyan_sound_board` is instantiated inside `pooyan.vhd` — the top wrapper
  wires only the `pooyan` entity; do not instantiate the sound board again.
- `vga_scandoubler.v` is self-contained (its `vgascanline_dport` and
  `color_dimmed` submodules are in the same file) — importing that one file is
  enough.
- `vga_scandoubler.v` is a cleanroom import (origin URL above) — modifying it
  is off limits; keep it byte-for-byte as imported. Any behavioral change goes
  in the `pooyan_basys3.vhd` wrapper instead.
- Keep the keyboard decoder on `clock_6` (the wrapper's divide-by-2 of
  `clock_12`, as in the DE10 wrapper) so `io_ps2_keyboard`/`kbd_joystick` run on
  the core's synchronous clock.

## Applying the T80 XOR-width fix

The pristine T80 core (`vhdl_pooyan_rev_0_2_2020_04_26/rtl_t80_350/T80.vhd`)
fails Vivado synthesis with "operands of logical operator '&' have different
lengths" (T80.vhd:562). The fix widens the `ioq` mask operand:

```vhdl
ioq := (ioq and '0'&x"07") xor ('0'&BusA); -- RB: modified for Vivado error ...
```

`pooyan_t80_xor_width.patch` in this directory applies that change to the
unmodified Dar source. From the `Pooyan-by-Dar/` directory (containing
`vhdl_pooyan_rev_0_2_2020_04_26/`):

```
patch -p1 < pooyan_t80_xor_width.patch
```

Verify it took:

```
grep -n "'0'&x\"07\"" vhdl_pooyan_rev_0_2_2020_04_26/rtl_t80_350/T80.vhd
```

