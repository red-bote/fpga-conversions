---
name: vivado-batch-build
description: Run Vivado synthesis/bitstream builds for these ports correctly - launch from /tmp so logs stay out of the repo, VIVADO env resolution, synth vs bitstream targets, reading WNS/timing results, expected warnings for placeholder projects. Use ONLY when actually running or debugging a Vivado run, not for doc or script questions.
---

# Running Vivado builds

Tool resolution: `$VIVADO` env var, else
`/tools/Xilinx/Vivado/2020.2/bin/vivado`.

## Log hygiene

Build scripts run from `/tmp` scratch dirs so `vivado.log` / `vivado.jou`
land outside the repo. When invoking vivado manually, `cd /tmp/opencode`
(or another /tmp dir) first. Never commit logs, journals, or bitstreams.

## Invocation

Prefer the machine Makefile:

```
make synth-<machine>      # synthesis only (resets synth_1 first)
make bitstream-<machine>  # implementation + write_bitstream
```

or call the machine's
`contrib/basys3/tools/make_<game>_basys3_bitstream.sh synth|bitstream`
directly. Scripts drive `vivado -mode batch -source <script>.tcl`; logs and
journal land in the cwd, which is why the cwd must be /tmp scratch.

Typical flow: `make setup-<machine>` (sources + PROM VHDL), then clk_wiz /
patch as available, then synth / bitstream.

## Reading results

- Success: run completes with 0 ERRORs; bitstream written.
- Timing: find WNS in the log / timing summary (`grep -i "worst negative"`).
  A negative WNS means unmet timing - do not ship that bitstream.
- CRITICAL/WARNING noise: judge individually. Missing-file warnings for the
  not-yet-generated clk_wiz_0 wrappers are expected between create_prj and
  clk_wiz steps.

## Run-level logs and reports

The driver-level `vivado.log` / `vivado.jou` stay in the /tmp cwd, but
`launch_runs` writes per-run logs inside the extracted tree (build artifacts,
removed by `make clean`):

- Errors:           `.runs/impl_1/runme.log` (and `.runs/synth_1/runme.log`)
- Timing WNS/TNS:   `.runs/impl_1/<game>_basys3_timing_summary_routed.rpt`
                    ("Design Timing Summary" table)
- Placed IO/pins:   `.runs/impl_1/<game>_basys3_io_placed.rpt`

## GUI Vivado coexistence

A user GUI session may run alongside batch builds (`pgrep -af vivado`; its
cwd hints at what it holds). Before a batch build:

- Check for stale locks (`<game>_basys3.xpr.lck`); clear them only when no
  GUI has that project open.
- `make create_prj` does `cp -f` of the tracked `.xpr` and will clobber any
  GUI-saved project state.
- After an aborted build, clear stale `.lck` files before rerunning.

## Placeholder projects

Doc-only ports carry faithful Makefiles/create_project.sh whose deep targets
(clk_wiz, patch, synth, bitstream) fail until their basys3 assets are ported.
That is intentional; do not "fix" it by deleting targets.
