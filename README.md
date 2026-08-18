# FPGA ports to the Digilent Basys 3

Ports of Dar's FPGA hardware projects (`darfpga@aol.fr`, <http://darfpga.blogspot.fr>)
to the Digilent Basys 3 (Artix-7, part `xc7a35tcpg236-1`), by Red~Bote. Each
machine is an independent project under its own `<Machine>-by-Dar/` directory,
built with Vivado 2020.2.

Operational rules live in `.opencode/rules.md` and `AGENTS.md` (terminology,
git, filesystem scope, tool paths). Each machine's `README.md` is the single
source of truth for that machine's design and build.

## Status

`Pooyan-by-Dar/` is the reference, fully-scripted port: it ships a `Makefile`
and `contrib/basys3/` build scripts. Use it as the template when bringing up the
other machines.

Every other `<Machine>-by-Dar/` currently contains only its design `README.md`
plus any synthesis-fix `*.patch`; the Dar source trees are fetched/extracted
locally and are not checked in.

## Machine index

| Machine | Core clock | Project / top entity | Patch | Romset(s) |
|---|---|---|---|---|
| Berzerk (Stern 1980) | 10 MHz | `berzerk_xc7/berzerk_xc7.xpr`, `rtl_top` | `berzerk_reset_sensitivity.patch` | `berzerk.zip` |
| Bagman (Stern 1982) | 12 MHz | `basys3/bagman_basys3.xpr`, `bagman_basys3` | `bagman_xor_width.patch` | `bagman.zip` |
| Burnin' Rubber (Data East 1982) | 12 + 6 MHz | `basys3/burnin_rubber_basys3.xpr`, `burnin_rubber_basys3` | — | `brubber.zip` |
| Galaga (Namco/Midway 1981) | 36 MHz | `basys3/galaga_basys3.xpr`, `galaga_basys3` | `galaga_credit_mode_fix.patch` | `galaga.zip` + `galagamw.zip` |
| Kick (Midway MCR 1981) | 40 MHz | `basys3/kickman_basys.xpr`, `kickman_basys3` (project dir lacks trailing `3`) | — | `kick.zip` |
| Popeye (Nintendo 1982) | 40.32 MHz | `popeye_xc7/popeye_xc7.xpr`, `rtl_top` | `popeye_linmix_sensitivity.patch` | `popeye.zip` + `popeyeu.zip` |
| Pooyan (Konami 1982) | 12 + 14 MHz | `basys3/pooyan_basys3/pooyan_basys3.xpr`, `pooyan_basys3` | `pooyan_de10_lite_to_basys3.patch`, `pooyan_t80_xor_width.patch` | `pooyan.zip` |
| Sky Skipper (Nintendo 1981) | 40 MHz | `basys3/sky_skipper_basys3.xpr`, `sky_skipper_basys3` | — | `skyskipr.zip` |
| Solar Fox (Bally Midway 1981) | 40 MHz | `basys3/solarfox_basys3.xpr`, `solarfox_basys3` | — | `solarfox.zip` |
| Time Pilot (Konami 1982) | 12.288 + 14.318 MHz | `basys3/time_pilot_basys3.xpr`, `time_pilot_basys3` | — | `timeplt.zip` |

Directory naming is not uniform: `Bagman-FPGA-Dar` and `Berzerk-FPGA-by-Dar`
differ from the `-by-Dar` convention.

The `—` patch entries mark machines that need no synthesis-fix patch. Machines
needing two romsets (`galaga`, `popeye`) require the extra set for CPU/speech
ROMs absent from the plain set.

## Common build workflow

Per machine, from its own directory (see the machine's `README.md` for the exact
file names, MMCM constants, and verify commands):

1. **Extract the Dar source** zip into the machine directory (`vhdl_<machine>_rev_.../`).
2. **Apply any synthesis-fix patch** (`patch -p1 < <machine>_*.patch`), then
   confirm it took with the `grep` given in the machine README.
3. **Generate the PROM VHDL** from the staged romset: unzip
   `~/roms/<set>.zip` into `tools/<machine>_unzip/`, then run
   `./make_<machine>_proms.sh` from that directory. The generated `*.vhd` are
   referenced in place by the Vivado project, so the build needs only the
   staged roms + the script.
4. **Generate the `clk_wiz_0` MMCM IP** deriving the core clock(s) from the
   100 MHz Basys 3 oscillator.
5. **Run synthesis/implementation from `/tmp`** so `vivado.log`/`vivado.jou`
   stay outside the repository.

Tool/path resolution is `ENV_VAR → project default → interactive prompt`:
Vivado `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`; roms `ROMZIP` →
`~/roms/`.

## Common Basys 3 platform

All ports share the same IO convention (see each machine README for the wrapper
port map): PS/2 keyboard on JB, JA joystick (active-low, switch to GND)
OR-merged with it, mono (or left-channel) PWM audio on PmodAMP2 at JC, 4-4-4 RGB
VGA, and `btnC` = reset (active-high). `sw14` = sound enable, `sw15` = AMP gain.
Video is 31 kHz progressive VGA; scan doubling is either built into the core or
added via an imported MiST/DECA scandoubler.

## Copyright

Roms and the generated PROM VHDL are copyrighted MAME-derived content and are
never committed or distributed. The `.patch` files are the tracked record of
changes to pristine Dar sources.
