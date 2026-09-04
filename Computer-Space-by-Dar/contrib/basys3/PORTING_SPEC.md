# Computer-Space-by-Dar — Porting spec

Upstream: `vhdl_computer_space_rev_1_1_2017_11_22.zip` (darfpga@aol.fr,
<http://darfpga.blogspot.fr>), which extracts as `SRC_DIR` per
`setup_computer_space.sh`. Project/top entity: `computer_space_basys3`. Core
clock: 6 MHz video pixel clock (`game_clk`) with a ~50 MHz `clock_50` for
timers/noise/sound. Computer Space is a discrete-TTL game core with no romset
and no `make_*_proms.bat`; its six `sound_*` roms are generated from Intel-HEX
by `contrib/tools/gen_sound_roms.py` instead of a `prep_roms.sh` chain.

Port status is tracked in the root `README.md` §Status, not here (per
`.opencode/rules.md` §"Documentation scope (PORTING_SPEC.md)").

## Clocking (`clk_wiz_0`, scripted in `make_clk_wiz_0.sh`)

Single MMCM. The MiST `scandoubler.v` needs `clk_sys` to be **exactly 2×**
`ce_x1`; an auto-selected VCO would produce a non-exact ratio and a black
screen, so the VCO is forced to 600 MHz:

- `CLKFBOUT_MULT_F = 6.0`, `CLKOUT0_DIVIDE_F = 12`, `CLKOUT1_DIVIDE = 100`,
  `CLKOUT2_DIVIDE = 50` → `clk_out0` = 50.000 MHz, `clk_out1` = 6.000 MHz
  (`game_clk`), `clk_out2` = 12.000 MHz.

The 12 MHz `clk_out2` supplies the scandoubler `clk_sys` = 2× `game_clk`
(6 MHz), satisfying its exactly-2× requirement. The 50 MHz `clk_out0` feeds
the core's `clock_50`.

## Video path

Computer Space uses the imported MiST `mist/scandoubler.v` for 31 kHz
progressive VGA (same core-family wiring as Galaga/Phoenix/Xevious/Zaxxon).
The core drives the scandoubler with its own `hsync`/`vsync` and monochrome
`video` from `computer_space_top`:

- **Dual-mode output (`sw(13)`, fleet TV/VGA switch convention)**:
  - `sw(13) = '0'` (VGA, 31 kHz): scandoubler output.
  - `sw(13) = '1'` (TV, 15 kHz): native RGB + composite sync on HS.

White-on-black monochrome picture (`video` is a 4-bit grey/white bus).

## Controls design

The core exposes discrete parallel input ports at the `computer_space_top`
boundary (`signal_ccw`, `signal_cw`, `signal_thrust`, `signal_fire`,
`signal_start`) — there is no in-core PS/2 decode, so the wrapper owns input
merging:

- **PS/2 keyboard** (JB) via the shared `kbd_joystick.vhd` decode of
  `joyPCFRLDU(7:0)`: bit0 = up (thrust), bit2 = left (CCW), bit3 = right
  (CW), bit4 = space (fire), bit6 = F2 (start).
- **JA joystick**, active-low (press shorts pin to GND; XDC `PULLUP true`),
  OR-merged with the keyboard bits using `not JA(x)`:
  - `signal_ccw <= joyPCFRLDU(2) or not JA(1)` (JA2 = left/CCW)
  - `signal_cw <= joyPCFRLDU(3) or not JA(0)` (JA1 = right/CW)
  - `signal_thrust <= joyPCFRLDU(0) or not JA(3)` (JA4 = up/thrust)
  - `signal_fire <= joyPCFRLDU(4) or not JA(4)` (JA7 = fire)
  - JA3 is spare (this core has no "down"/reverse input).
- **Pushbuttons** (active-high, Basys3 pull-down, same convention as `btnC`):
  `signal_start <= joyPCFRLDU(6) or btnU or btnD or btnL or btnR` — any
  pushbutton doubles as start; `btnC` = reset.

## Rocket-missile fire fix

The pristine `rtl/motion_board.vhd` has an unreachable-clear bug in the
rocket-missile fire/lifetime process: the counter-expiry check is an `elsif`
sibling of the "increment while firing" branch, so once `missile_timer`
latches `'1'` on the first fire it can never reach the clear branch — fire
is permanently dead after the first launch. `computer_space_rocket_timer_synth_fix.patch`
began as a synthesis-only fix (moving the integer signals out of the process
sensitivity list, preserving the same bug in nested form) and now also carries
the functional fix: the counter-expiry check moves inside the
`missile_timer = '1'` branch and is evaluated first each clock edge, so the
clear is reachable and sustained/refired fire works.

Design note on patch strategy: `motion_board.vhd` is the one exception to the
usual "reference pristine sources in place" convention — the project imports
its own copy (`sources_1/imports/rtl/motion_board.vhd`), and `make create_prj`
copies it fresh from `rtl/motion_board.vhd` and applies the two
`motion_board` patches to that copy only. The pristine file is never modified.
See the machine `README.md` for the exact wiring and verify commands.

## Other wiring decisions

- **Reset**: `reset <= btnC or not mmcm_locked` (project-standard pattern);
  `clk_wiz_0`'s `reset` driven by `btnC` directly.
- **Audio**: mono PWM output on PmodAMP2 (JC), reusing the core's native
  audio path (`wav_out`/`audio` from `computer_space_top`); `sw14` = sound
  enable (`O_PMODAMP2_SHUTD`), `sw15` = AMP gain (`O_PMODAMP2_GAIN`) — the
  fleet-standard pair.
- **Display mode**: `sw(13)` toggles 31 kHz VGA vs 15 kHz TV (see "Video
  path").
- **Debug hex display / LEDs**: not ported — no Basys3 machine here carries
  7-segment wiring, and the core's LED outputs are static/non-essential
  (matches the rest of the fleet).
