# AGENTS.md

Operational guidance for AI sessions in this repository. See also
`.opencode/rules.md` for terminology, filesystem scope, and git rules.

## What this repo is

FPGA ports of Dar's arcade hardware (`darfpga@aol.fr`) to the Digilent Basys 3
(Artix-7 `xc7a35tcpg236-1`), built with Vivado 2020.2. Each machine is an
independent project under its own `<Machine>-by-Dar/` directory.

`Pooyan-by-Dar/` is the reference, fully-scripted port. Use it as the template
for new work.

## Repo layout

- Each `<Machine>-by-Dar/` owns its own `Makefile`, `contrib/`, and
  `PORTING_SPEC.md`.
- The root `Makefile` delegates to per-machine Makefiles:
  `make <step>-<machine>` (e.g. `make setup-galaga`, `make synth-pooyan`).
- Root `README.md` is the machine index with clock frequencies, project names,
  and romsets.
- Each machine's `README.md` is the single source of truth for that machine's
  design and build.
- `tools/vhdl_formatter.py` — stdlib-only VHDL indent/alignment formatter
  (`--check`, `--align`, `--indent N`).

## Build workflow (per machine)

Steps must run in order. From the machine directory:

1. `make setup` — fetches Dar source archive (SHA-256 verified), applies
   synthesis-fix patches, compiles `make_vhdl_prom`, converts the `.bat` to
   `.sh`, stages romsets, generates PROM VHDL.
2. `make create_prj` — creates Vivado project, copies `.xpr`/`.xdc`, imports
   scandoubler. (Not all machines have this step.)
3. `make clk_wiz` — generates `clk_wiz_0` MMCM IP (100 MHz → core clocks).
4. `make patch` — regenerates top-level wrapper and porting patch.
5. `make synth` — synthesis only (resets `synth_1` first).
6. `make bitstream` — implementation + `write_bitstream`.
7. `make clean` — removes the Vivado project/build tree only.

Root-level shorthand: `make all-galaga`, `make bitstream-pooyan`, etc.

## Tool / path resolution

`ENV_VAR → project default → interactive prompt`:
- Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
- ROMs: `ROMZIP` → `~/roms/<set>.zip` (some machines use `ROMZIP2`)

**Vivado builds run from `/tmp`** so `vivado.log`/`vivado.jou` stay outside the
repo.

## Copyright hard rule

Roms and generated PROM VHDL are copyrighted MAME-derived content — **never
commit or distribute** them. `.patch` files are the tracked record of changes to
pristine Dar sources.

## VHDL formatting

Run `tools/vhdl_formatter.py` on VHDL files. Dependency-free (stdlib only).
Idempotent. `--check` for CI, `--align` for column alignment.

## Common gotchas

- Directory naming is not uniform: `Bagman-FPGA-Dar` and `Berzerk-FPGA-by-Dar`
  differ from the `-by-Dar` convention.
- Machines needing two romsets (Galaga, Popeye) require the extra set for
  CPU/speech ROMs absent from the plain set.
- Galaga's `rtl_dar/galaga.vhd` has been modified to expose `dip_switch_a`/`dip_switch_b`
  as entity input ports (replacing hard-coded constants). This is captured as
  `contrib/code/galaga_dipswitch.patch` and applied during `make setup` (see
  PORTING_SPEC §7.3, §8). The upstream Basys3 port drives these from
  `sw(12 downto 0)` with inverted polarity.
- Galaga and Burnin' Rubber import `mist/scandoubler.v` (15 kHz core output);
  Time Pilot and Pooyan import `vga_scandoubler.v` (DECA).
- The five machines without a full Basys 3 bring-up (Burnin' Rubber, Kick,
  Popeye, Sky Skipper, Solar Fox) have placeholder
  `contrib/basys3/vivado/create_project.sh` — their XDC, top-level wrapper, and
  clk-wiz scripts still need to be created.
- The shipped `make_<game>_proms.bat` files have CRLF endings; `prep_roms.sh`
  converts them to LF via sed before execution.
