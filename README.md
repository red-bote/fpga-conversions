# FPGA ports to the Digilent Basys 3

Ports of Dar's FPGA hardware projects (`darfpga@aol.fr`, <http://darfpga.blogspot.fr>)
to the Digilent Basys 3 (Artix-7, part `xc7a35tcpg236-1`), by Red~Bote. Each
machine is an independent project under its own `<Machine>-by-Dar/` directory,
built with Vivado 2020.2.

Operational rules live in `.opencode/rules.md` and `AGENTS.md` (terminology,
git, filesystem scope, tool paths). Each machine's `README.md` is the single
source of truth for that machine's design and build.

## Status

Time-Pilot-by-Dar, Pooyan-by-Dar, Bagman-FPGA-Dar, Berzerk-FPGA-by-Dar, Burnin-Rubber-by-Dar, 
Galaga-Midway-by-Dar, Tron-by-Dar, Kick-Midway-MCR-by-Dar, Burger-Time-by-Dar 
and Popeye-by-Dar are complete, fully-scripted, hardware-verified ports.

Defender-by-Dar is fully scripted (assets authored end to end from the
BurgerTime/Burnin-Rubber reference, same scandoubler core-family wiring) but
not yet hardware-verified: `make setup create_prj clk_wiz patch` are
exercisable; `make synth` / `make bitstream` have not been run.

Phoenix-by-Dar is fully scripted, synthesized, and bitstream-built
(0 critical warnings/errors through implementation) but not yet
hardware-verified. Its core exposes only composite sync and only a PS/2
keyboard input, unlike every other machine in this project; the Basys3
wrapper adds a duration-threshold composite-sync separator (new wrapper-only
logic feeding the imported MiST scandoubler) and a control-input patch to
the pristine core (`contrib/code/phoenix_expose_control_ports.patch`) —
both unverified until hardware bring-up. See
`Phoenix-by-Dar/contrib/basys3/PORTING_SPEC.md` for the full design record.

Every machine directory now carries a scripted setup: `contrib/tools/setup_<game>.sh`
(fetches the Dar archive into a gitignored `dloads/` cache with an embedded
SHA-256 check, extracts it, applies any synthesis-fix patches) chaining into
`contrib/tools/prep_roms.sh` (compiles `make_vhdl_prom`, converts the
`make_<game>_proms.bat`, stages the romset(s), generates the PROM VHDL), plus a
`Makefile` wrapping both. 

## Machine index

| Machine | Core clock | Project / top entity | Patch | Romset(s) |
|---|---|---|---|---|
| Berzerk (Stern 1980) | 10 MHz | `basys3/berzerk_basys3.xpr`, `berzerk_basys3` | `berzerk_reset_sensitivity.patch` | `berzerk.zip` |
| Bagman (Stern 1982) | 12 MHz | `basys3/bagman_basys3.xpr`, `bagman_basys3` | `bagman_xor_width.patch` | `bagman.zip` |
| Burnin' Rubber (Data East 1982) | 12 + 6 MHz | `basys3/burnin_rubber_basys3.xpr`, `burnin_rubber_basys3` | — | `brubber.zip` |
| BurgerTime (Data East 1982) | 12 + 6 MHz | `basys3/burger_time_basys3.xpr`, `burger_time_basys3` | — | `btime.zip` |
| Defender (Williams 1981) | 12 + 3.58 MHz | `basys3/defender_basys3.xpr`, `defender_basys3` | — | `defender.zip` |
| Galaga (Namco/Midway 1981) | 36 MHz | `basys3/galaga_basys3.xpr`, `galaga_basys3` | `galaga_bgpalette_xor_length_fix.patch`, `galaga_credit_mode_fix.patch`, `galaga_vga_sync.patch` | `galaga.zip` + `galagamw.zip` |
| Kick (Midway MCR 1981) | 40 MHz | `basys3/kick_basys3.xpr`, `kick_basys3` | — | `kick.zip` |
| Popeye (Nintendo 1982) | 40.32 MHz | `basys3/popeye_basys3.xpr`, `popeye_basys3` | `popeye_linmix_sensitivity.patch` | `popeye.zip` + `popeyeu.zip` |
| Phoenix (Amstar 1980) | 11 + 50 MHz | `basys3/phoenix_basys3.xpr`, `phoenix_basys3` | `phoenix_expose_control_ports.patch` | `phoenix.zip` |
| Pooyan (Konami 1982) | 12 + 14 MHz | `basys3/pooyan_basys3/pooyan_basys3.xpr`, `pooyan_basys3` | `pooyan_de10_lite_to_basys3.patch`, `pooyan_t80_xor_width.patch` | `pooyan.zip` |
| Sky Skipper (Nintendo 1981) | 40 MHz | `basys3/sky_skipper_basys3.xpr`, `sky_skipper_basys3` | — | `skyskipr.zip` |
| Solar Fox (Bally Midway 1981) | 40 MHz | `basys3/solar_fox_basys3.xpr`, `solar_fox_basys3` | — | `solarfox.zip` |
| Time Pilot (Konami 1982) | 12.288 + 14.318 MHz | `basys3/time_pilot_basys3.xpr`, `time_pilot_basys3` | — | `timeplt.zip` |
| Tron (Midway MCR 1982) | 40 MHz | `basys3/tron_basys3.xpr`, `tron_basys3` | — | `tron.zip` + `kick.zip` (color PROM) |

Directory naming is not uniform: `Bagman-FPGA-Dar` and `Berzerk-FPGA-by-Dar`
differ from the `-by-Dar` convention; `Sky-skipper-by-Dar` uses a lowercase `s`.

The `—` patch entries mark machines that need no synthesis-fix patch. Machines
needing two romsets (`galaga`, `popeye`) require the extra set for CPU/speech
ROMs absent from the plain set.

## Common build workflow

New ports are bootstrapped from the generic templates in `wip/machine/`
(Makefile, build-script templates, and the sample Basys 3 Vivado project);
see the root `PORTING_SPEC.md` for the full bring-up procedure.

Per machine, from its own directory (see the machine's `README.md` for the exact
file names, MMCM constants, and verify commands):

1. **Run `make setup`** (or `contrib/tools/setup_<game>.sh` directly). This
   fetches the Dar source archive into the machine's gitignored `dloads/` cache
   (SHA-256 verified against the hash embedded in the script; re-downloaded when
   missing or tampered), extracts it as `vhdl_<machine>_rev_.../`, applies any
   synthesis-fix patches, and chains into `contrib/tools/prep_roms.sh`, which
   compiles `make_vhdl_prom`, converts `make_<game>_proms.bat` to `.sh`, stages
   the romset(s) from `$ROMZIP`/`$ROMZIP2` (default `~/roms/<set>.zip`), and
   generates the PROM VHDL referenced in place by the Vivado project.

The manual equivalents, if needed:

1. **Extract the Dar source** zip into the machine directory (`vhdl_<machine>_rev_.../`).
2. **Apply any synthesis-fix patch** (`patch -p1 < <machine>_*.patch`), then
   confirm it took with the `grep` given in the machine README.
3. **Generate the PROM VHDL** from the staged romset: unzip
   `~/roms/<set>.zip` into `tools/<machine>_unzip/`, then run
   `./make_<machine>_proms.sh` from that directory.
4. **Stage the Vivado project** (`contrib/basys3/vivado/create_project.sh`),
   **generate the `clk_wiz_0` MMCM IP** deriving the core clock(s) from the
   100 MHz Basys 3 oscillator, then **run synthesis/implementation from `/tmp`**
   so `vivado.log`/`vivado.jou` stay outside the repository.

Tool/path resolution is `ENV_VAR → project default → interactive prompt`:
Vivado `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`; roms `ROMZIP` →
`~/roms/`.

Each machine Makefile prints a display-mode reminder via its `make help` target and
at the end of `make all` / `make bitstream`: if nothing appears on the display after
loading the bitstream, first try toggling the display mode (F8 on the PS/2 keyboard,
or sw(13); per-machine detail in the machine README) before troubleshooting further.
`make all-<machine>` / `make bitstream-<machine>` show it too, because they delegate
to the machine `all` / `bitstream`. Machines with no display-mode toggle print no
reminder.

## Common Basys 3 platform

All ports share the same IO convention (see each machine README for the wrapper
port map): PS/2 keyboard on JB, JA joystick (active-low, switch to GND)
OR-merged with it, mono (or left-channel) PWM audio on PmodAMP2 at JC, 4-4-4 RGB
VGA, and `btnC` = reset (active-high). `sw14` = sound enable, `sw15` = AMP gain.
Video is 31 kHz progressive VGA; scan doubling is either built into the core or
added via an imported scandoubler. Per machine: Galaga and Burnin' Rubber import
`mist/scandoubler.v` (their cores output 15 kHz only); Time Pilot and Pooyan
import `vga_scandoubler.v` (DECA); Bagman and Berzerk instantiate Dar's
`line_doubler` inside the core; Kick, Popeye, Sky Skipper and Solar Fox generate
progressive 31 kHz natively in the core (`tv15Khz_mode = '0'`). Phoenix also
imports `mist/scandoubler.v`, but its core exposes only composite sync (no
native hsync/vsync at all, unlike Galaga/Burnin-Rubber) — the Basys3 wrapper
adds a duration-threshold sync separator ahead of the scandoubler; see
`Phoenix-by-Dar/contrib/basys3/PORTING_SPEC.md`.

## Shared tools

`tools/vhdl_formatter.py` normalizes VHDL indentation to a fixed width per level
(`--indent`, default 2) and can optionally align `<=` and `:` columns (`--align`).
It is dependency-free (stdlib only), in-place or `--check`, and idempotent.

## Copyright

Roms and the generated PROM VHDL are copyrighted content and are
never committed or distributed. The `.patch` files are the tracked record of
changes to pristine Dar sources.
