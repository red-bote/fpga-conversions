# AGENTS.md

Operational rules live in `.opencode/rules.md` (loaded alongside this file);
follow it for terminology, git, and filesystem scope. This file adds repo
structure and the operational conditions rules.md explicitly allows.

## Layout

- This repo hosts multiple independent FPGA conversions: ports of Dar's FPGA
  arcade hardware to the Digilent Basys 3 (Artix-7, `xc7a35tcpg236-1`), built
  with Vivado 2020.2. One independent project per `<Machine>-by-Dar/` dir.
- `Pooyan-by-Dar/` is the reference, fully-scripted port (it has a `Makefile`
  and `contrib/basys3/` build scripts). Use it as the template when bringing up
  the other machines.
- Every other `<Machine>-by-Dar/` currently contains only its `README.md` plus
  synthesis-fix `*.patch` files; the Dar sources are not yet checked in. There
  is no aggregate root README.
- Each machine's `README.md` is the single source of truth for that machine's
  design and build (IO mapping, clocks, romset prom generation, patch
  application). Design lives there and in the scripts, not here.

## Operational conditions (allowed by .opencode/rules.md)

- Vivado build scripts run from `/tmp` so `vivado.log`/`vivado.jou` stay outside
  the repo.
- Tools/paths resolve as `ENV_VAR → project default → interactive prompt`:
  - Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
  - roms: `ROMZIP` → `~/roms/`
- `contrib/basys3/code/vga_scandoubler.v` is the canonical cleanroom import
  (hash-checked) — never modify it.

## Copyright & generated content

- ROM-derived PROM VHDL is generated from staged romsets; neither roms nor the
  generated PROM VHDL are ever committed or distributed.
- `.patch` files are the tracked record of changes to pristine Dar sources;
  apply them with `patch -p1` after the source tree is extracted.