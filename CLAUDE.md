# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Authoritative docs (read these first)

- `AGENTS.md` — operational guidance: what this repo is, repo layout, build workflow, tool/path resolution, copyright rule, common gotchas.
- `.opencode/skills/` — detailed how-tos: `port-dar-machine`, `vivado-batch-build`, `xpr-dependency-closure`, `romset-forensics`. Consult before starting a port or running a Vivado build.
- `.opencode/rules.md` — terminology, git usage rules, filesystem scope, documentation-scope rules. These are binding operational rules, not suggestions.
- Root `README.md` — machine index (clock frequencies, project/top-entity names, patches, romsets) and the Common Basys 3 platform section (IO conventions, scandoubler variants per machine).
- Each `<Machine>-by-Dar/README.md` — single source of truth for that machine's design and build.
- Each machine's `PORTING_SPEC.md` and the generic root `PORTING_SPEC.md` — porting-decision record; consult before deviating from the reference port. Location is mid-migration: canonical target is `<Machine>-by-Dar/contrib/basys3/PORTING_SPEC.md` (already there for Berzerk-FPGA-by-Dar, Burnin-Rubber-by-Dar, Tron-by-Dar, Bagman-FPGA-Dar, Kick-Midway-MCR-by-Dar, Popeye-by-Dar, Sky-skipper-by-Dar, Solar-Fox-by-Dar, Burger-Time-by-Dar, Defender-by-Dar); Galaga-Midway-by-Dar, Pooyan-by-Dar, and Time-Pilot-by-Dar still have it at the machine-directory top level pending migration. Check both locations.

Do not restate content from `AGENTS.md` / `.opencode/rules.md` / `README.md` elsewhere in this repo (per `.opencode/rules.md` §Documentation scope) — script design lives in the scripts themselves, terminology/git/filesystem rules live in `.opencode/rules.md`, and platform IO conventions live in the root `README.md`.

## Commands

Build workflow (per-machine step sequence and semantics): see `AGENTS.md` §"Build workflow". From the repo root, the delegating shorthand `make <step>-<machine>` hyphenates multi-word step names (`create-prj-galaga`, `clk-wiz-galaga`) even though the per-machine Makefile targets use underscores (`create_prj`, `clk_wiz`); run `make help` for the current step matrix.

**Root Makefile coverage gap**: only 9 of the 13 ported machines have root-level delegation targets (Galaga, Pooyan, Time-Pilot, Bagman, Berzerk, Tron, Kick, Burger-Time, Defender). Burnin-Rubber-by-Dar, Popeye-by-Dar, Sky-skipper-by-Dar, and Solar-Fox-by-Dar each have their own machine-level `Makefile` but no root shorthand — build these via `make <step>` from inside the machine directory.

VHDL formatting: `tools/vhdl_formatter.py` (see `AGENTS.md` §"VHDL formatting" for flags).

There is no automated test suite; correctness is verified through Vivado synthesis/implementation/timing closure and (where noted in a machine's README) hardware bring-up.

## Architecture

Cross-cutting layout detail not carried in `AGENTS.md` (excluded there by `.opencode/rules.md` §"Documentation scope (AGENTS.md)") or in the root `README.md`:

- **Per-machine independence**: each `<Machine>-by-Dar/` owns its own `Makefile`, `contrib/`, `README.md`, `PORTING_SPEC.md`. Nothing is shared at build time except `tools/vhdl_formatter.py` and the porting conventions.
- **`contrib/` layout** (per machine): flat `contrib/code/` — synthesis-fix `*.patch` records for the pristine Dar source, plus (Galaga, Burnin' Rubber) the canonical `mist/scandoubler.v` import, never modify; flat `contrib/tools/` — source-setup (`setup_<machine>.sh`) and rom-prep (`prep_roms.sh`) scripts. Under `contrib/basys3/`: `code/` — the DECA `vga_scandoubler.v` import (Pooyan, Time-Pilot; also never modify) plus the machine's `*_de10_lite_to_basys3.patch` documentation record; `vivado/` — `.xpr`, `.xdc`, and (all machines but Pooyan) `make_clk_wiz_0.sh`; `tools/` — `make_de10_lite_to_basys3_patch.sh` and `make_<machine>_basys3_bitstream.sh` (Pooyan's `make_clk_wiz_0.sh` lives here instead).
- **Non-nested project layout**: the `.xpr` lives directly at `basys3/<machine>_basys3.xpr` with sources under `basys3/<machine>_basys3.srcs/`.
- **Sky-skipper-by-Dar and Solar-Fox-by-Dar are earlier-stage**: each has `Makefile` + `contrib/` + `README.md` but no `contrib/basys3/vivado/` tree at all — no `.xpr`, `.xdc`, or `make_clk_wiz_0.sh` — and neither appears in root `README.md` §Status. Their Makefiles reference `$(VIVADO)/make_clk_wiz_0.sh`, which does not exist yet.

For copyright rule, tool/path resolution (`VIVADO`, `ROMZIP`), and the `/tmp` build-scratch convention, see `AGENTS.md`. For per-machine IO pinout and scandoubler convention, see root `README.md` §"Common Basys 3 platform".
