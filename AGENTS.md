# AGENTS.md

FPGA ports of Dar's arcade hardware to the Digilent Basys 3 (Artix-7 `xc7a35tcpg236-1`, Vivado 2020.2). Each machine is its own `<Machine>-by-Dar/` directory.

## Start here

- Operational rules (terminology, git, filesystem scope) are the source of truth in `.opencode/rules.md` — follow it and this file together; both are auto-loaded via `.opencode/opencode.json`.
- `README.md` has the machine index, common IO convention, and shared build workflow. Each machine's own `README.md` is the single source of truth for that machine's design and build.
- `Pooyan-by-Dar/` is the reference, fully-scripted port (Makefile + `contrib/basys3/` scripts). Use it as the template when bringing up the other machines.

## Terminology (mandatory)

Per `.opencode/rules.md`: "hardware" = a platform directory; "machine" = hardware + a specific romset. Say **roms/romset**, never "MAME roms"; describe **machines/hardware**, never "games"/"arcade". Upstream filenames keep their names (e.g. `make_pooyan_proms.sh`).

## Machine layout

- `Pooyan-by-Dar/` — full scripted port. `contrib/basys3/{code,tools,vivado}/` holds patches, build scripts, and the top-level XDC/XPR; the actual Vivado project lives under the extracted `vhdl_pooyan_rev_0_2_2020_04_26/basys3/` tree.
- `Time-Pilot-by-Dar/` — second complete, fully-scripted, hardware-verified port (same layout as Pooyan). Its Dar source tree is extracted locally and not checked in.
- Other machines are scaffold-only: a design `README.md` plus `contrib/basys3/`; their Dar source trees are not checked in.

## Build workflow (order matters)

Per machine, from its own directory (exact names/verify greps in that machine's README):

1. Extract the Dar source zip (→ `vhdl_<machine>_rev_.../`).
2. Apply any synthesis-fix `*.patch` (`patch -p1 < <machine>_*.patch`), confirm with the README's `grep`.
3. Generate PROM VHDL from the staged romset: unzip `~/roms/<set>.zip` into `tools/<machine>_unzip/`, run `./make_<machine>_proms.sh` from there. Generated `*.vhd` are referenced in place; the build needs the staged roms + script only.
4. Generate the `clk_wiz_0` MMCM IP (derives core clock(s) from the 100 MHz oscillator).
5. Run synthesis/implementation from `/tmp` so `vivado.log`/`vivado.jou` land outside the repo.

## Tool/path resolution

`ENV_VAR → project default → interactive prompt`:
- Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
- roms: `ROMZIP` → `~/roms/`

## Hard constraints

- Never modify `contrib/basys3/code/vga_scandoubler.v` (or its per-machine copy) — hash-checked canonical cleanroom import.
- Roms and the generated PROM VHDL are copyrighted MAME-derived content — never commit or distribute them. The `*.patch` files are the tracked record of changes to pristine Dar sources.
- Vivado build scripts run from `/tmp`; keep `vivado.log`/`vivado.jou` outside the repo.

## Formatting

`tools/vhdl_formatter.py` normalizes VHDL indentation (default 2 spaces/level), optional `--align` for `<=`/`:` columns, in-place or `--check`, idempotent, stdlib-only.

## Support scripts

Script design (for `make_*_proms.sh`, `contrib/basys3/*.sh`, `Makefile`) lives in the scripts and root `README.md`, not here. See `.opencode/rules.md`.
