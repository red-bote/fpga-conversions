# AGENTS.md

Operational rules for agents working in this repository. Keep this file to
operational conditions only — design/script details live in the root `README.md`,
each machine's `README.md`/`PORTING_SPEC.md`, and the scripts themselves. The
authoritative rules are `.opencode/rules.md` and the root `CLAUDE.md`; this file
mirrors them so any agent picks them up regardless of which instruction file it
reads.

## Terminology (source of truth — use this wording everywhere)

- hardware = a hardware platform built in FPGA (one `<Machine>-by-Dar/` directory).
- machine  = a hardware platform combined with a particular romset.
- Say "roms"/"romset", never "MAME roms"; describe machines/hardware, never
  "games"/"arcade" (upstream filenames keep their names, e.g. `make_pooyan_proms.sh`).

## Git

- Do not run git commands unless explicitly requested, and then only once — a
  single read (status/log/diff). Do not re-check.

## Filesystem scope

- Read only files inside this repo unless given explicit permission. Exceptions:
  `/tmp` (scratch; Vivado build scripts run from `/tmp` so `vivado.log`/`vivado.jou`
  land outside the repo), `~/roms/` (`ROMZIP`), and the `VIVADO` tool path below.

## Tool / path resolution

Resolve as `ENV_VAR → project default → interactive prompt`:
- Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
- roms: `ROMZIP` → `~/roms/`

## Canonical file — never modify

- `contrib/basys3/vga_scandoubler.v` is the canonical cleanroom import. Never modify it.

## Verification

No unit-test/build/lint toolchain exists: this is FPGA hardware, verified via
Vivado synthesis/implementation. There is no command to run to verify code
changes except Vivado builds.
