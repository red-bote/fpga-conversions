# Operational rules (meta, not functional)

## Terminology (source of truth — use this wording everywhere)

- hardware = a particular hardware platform being built in FPGA (one `<Machine>-by-Dar/` directory).
- machine  = a hardware platform combined with a particular romset (some hardware support multiple romsets).
- Say "roms"/"romset", never "MAME roms"; describe machines/hardware, never "games"/"arcade" (upstream filenames keep their names, e.g. `make_pooyan_proms.sh`).

## Git

- Do not look at git unless specifically requested to do so, only once. Never run git commands (status, log, diff, checkout, …) unprompted. When explicitly requested, inspect once — a single read — and don't keep re-checking.

## Filesystem scope

- Do not read anything outside this repository directory without explicit
  permission (no sibling or backup checkouts,
  nothing under `$HOME`, no symlinked locations). Diagnose and reason only from
  files inside the repo.
- Exceptions (documented elsewhere in these rules): `/tmp` (scratch, and the
  Vivado build scripts that run from `/tmp`), `~/roms/` (`ROMZIP`), and the
  `ENV_VAR` paths from the tool resolution rule (`VIVADO`). Anything
  else outside the repo requires the user's explicit permission.

## Documentation scope (AGENTS.md)

- AGENTS.md must not carry design information about the support scripts
  (`make_*_proms.sh`,
  `contrib/basys3/*.sh`, `Makefile`) unless explicitly instructed otherwise
  in these Operational Rules. Script design lives in the scripts themselves
  and in the root `README.md`; keep AGENTS.md to operational conditions.

- Explicitly instructed (AGENTS.md may carry these):
  - Vivado build scripts run from `/tmp` so `vivado.log`/`vivado.jou` land
    outside the repo.
  - Tools/paths resolve as `ENV_VAR → project default → interactive prompt`:
    - Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
    - roms: `ROMZIP` → `~/roms/`
   - `contrib/basys3/vga_scandoubler.v` is the canonical cleanroom import — never modify it.
