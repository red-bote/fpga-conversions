# Phoenix-by-Dar — Porting spec

Upstream: `vhdl_phoenix_DE10_lite.zip` (darfpga@aol.fr,
<http://darfpga.blogspot.fr>), no internal top-level folder (extracted
directly as `SRC_DIR`, per `setup_phoenix.sh`). Project/top entity:
`phoenix_basys3`. Core clock: 11 MHz (pixel clock 5.5 MHz = `clk11`
internally divided by 2). Video path: composite-sync-only core, no native
VGA/scandoubled output — see "Video path" below.

Port status is tracked in the root `README.md` §Status, not here (per
`.opencode/rules.md` §"Documentation scope (PORTING_SPEC.md)").

## Clocking (`clk_wiz_0`, already scripted in `make_clk_wiz_0.sh`)

Single MMCM, VCO 1100 MHz: `clk_out1` = 11 MHz (core: `clock_11` in to the
`phoenix` entity), `clk_out2` = 50 MHz (audio: `clock_50` in — the pristine
DE10 top feeds the raw 50 MHz board oscillator directly to this port; the
`phoenix_effect1/2/3`/`phoenix_music` blocks divide it internally to 10 MHz,
so the Basys3 wrapper reuses the MMCM's synthesized 50 MHz output for the
same purpose instead of a second board oscillator).

## Video path

### Problem

`phoenix_video.vhd` (the core's video generator) implements RS-170-style
composite sync directly — pre-equalizing pulses, vsync serration, and
post-equalizing pulses, each timed off the internal `hcnt`/`vcnt` counters
(`sync <=` combinational mux at `phoenix_video.vhd:200+`) — and exposes only
that single composite signal as `sync` (forwarded to the `phoenix` entity's
`video_csync` port). **No separate hsync/vsync exist anywhere in the
pristine design**; `video_hs`/`video_vs` are commented out both at the
`phoenix` entity (`phoenix.vhd:26-27`) and the DE10-lite top
(`phoenix_de10_lite.vhd`). This matches the upstream `README.txt`: "TV mode
only RBG 15kHz" — Dar never implemented VGA output for this core. The DE10
top puts `csync` directly on `vga_hs` with `vga_vs` tied high (composite
sync riding the HS line, matching this project's own "TV mode" convention
for other machines).

The already-staged MiST `scandoubler.v` requires genuine separate `hs_in`/
`vs_in` (confirmed in-module: `vs_out` is a bare registered copy of `vs_in`,
`hs_in` edges drive the internal line-length/doubling counters — it does not
separate composite sync itself). Feeding it composite sync directly would
leave `vs_out` static (never toggling), so it cannot be wired as-is.

### Chosen approach: csync separator authored in the Basys3 wrapper

Decision (user-confirmed): author a sync separator as new logic in
`phoenix_basys3.vhd` only — no changes to any pristine `rtl_dar`/`rtl_T80`
file — that derives clean `hs`/`vs` from `video_csync`, then feeds the
existing scandoubler for real 31 kHz VGA. This is unverified until hardware
bring-up; no Dar reference validates it for this core (the upstream design
never produced separate H/V for Phoenix). **Fallback (plan B) if the
separator does not lock on hardware**: patch `phoenix_video.vhd` to compute
and expose separate `hsync`/`vsync` from its already-internal `hcnt`/`vcnt`
counters, forwarded through the `phoenix` entity's commented-out
`video_hs`/`video_vs` ports — this would be the first patch in the repo that
adds functionality to a pristine core file rather than fixing a synthesis
error, so it needs its own review before authoring if it becomes necessary.

### Separator design intent

Standard LM1881-style duration discrimination, sampled on `video_clk`
(5.5 MHz, the core's own pixel-clock output — already exposed at the
`phoenix` entity boundary, so no pristine file needs touching to obtain it):

- **`hs`**: derived directly from `video_csync`'s falling edges (registered/
  resynchronized to `video_clk`). During the vertical-blank equalizing/
  serration region this pulses at up to 2x the normal line rate; harmless,
  since that region is blanked in the displayed image regardless.
- **`vs`**: a free-running counter resets on every `video_csync` rising edge
  and increments while `video_csync` is low. If the accumulated low time
  exceeds roughly half a line period (~32 µs ≈ 176 `video_clk` cycles at
  5.5 MHz — normal sync pulses run ~4.7 µs / ~26 cycles per the
  `phoenix_video.vhd` pulse-width comments, so a half-line threshold cleanly
  separates ordinary hsync/equalizing pulses from vsync serration pulses),
  assert an internal `vsync_active` flag; edge-detect it to produce a clean
  `vs` pulse spanning the serration region.
- No exact `hcnt`/`vcnt` values are available to the wrapper (they are
  internal to `phoenix_video.vhd`, not forwarded to any entity port), so the
  threshold is duration-based rather than count-based — the standard
  technique for separating sync from a composite source with no counter
  access.

### Scandoubler wiring (once the separator exists)

Same component/port-map shape as Burnin-Rubber's (see
`Burnin-Rubber-by-Dar/contrib/basys3/PORTING_SPEC.md` for the full component
declaration and port table); values that differ for Phoenix:

| Port | Connected signal | Note |
|---|---|---|
| `clk_sys` | `clk_out1` (11 MHz) | MMCM core clock, already generated |
| `ce_x1` | `video_clk` (5.5 MHz, from the `phoenix` core instance) | Core's own pixel clock, already phase-locked to `clk_out1` (`clk11`/2 internally) — no extra divider needed, unlike Burnin-Rubber's separate `clk_out2` |
| `ce_x2` | `'1'` (literal) | Matches fleet convention |
| `scanlines` | `"00"` (literal) | Matches fleet convention — no scanline control implemented anywhere in this project |
| `hs_in` / `vs_in` | separator's `hs` / `vs` | See separator design above |
| `r_in` / `g_in` / `b_in` | `video_r & video_r & video_r` etc. | Core outputs 2 bits/channel (`video_r/g/b : std_logic_vector(1 downto 0)`); pad to `COLOR_DEPTH = 6` by triple replication. **No external blanking gate needed**: unlike Burnin-Rubber, the core already forces `video_r/g/b` to `"00"` internally during `hblank`/`vblank` (`fr_bit0`/`fr_bit1`/`bk_bit0`/`bk_bit1` are gated by `vblank`/`hblank_frgrd`/`hblank_bkgrd` at `phoenix.vhd:242-245`, feeding `color_id` which addresses a palette ROM whose index 0 is black) — confirmed by the DE10 top's own `blankn <= '1'` (constant, i.e. the DE10 top deliberately disables any external blanking mask and trusts the core) |

### Dual-mode output (`sw(13)`, matches the fleet's TV/VGA switch convention)

- `sw(13) = '0'` (VGA, 31 kHz): scandoubler output, as above.
- `sw(13) = '1'` (TV, 15 kHz): `video_csync` straight onto `vgaHsync`,
  `vgaVsync` tied `'1'`, native `video_r`/`video_g`/`video_b` passed through
  padded to 4 bits — this exactly reproduces the pristine DE10-lite top's
  behavior, so it is expected to work regardless of whether the separator
  does, giving a built-in fallback display path independent of plan B.

## Other wiring decisions

- **Reset**: `reset <= btnC or not mmcm_locked` (project-standard MMCM/reset
  pattern); `clk_wiz_0`'s own `reset` port driven by `btnC` directly.
- **Inputs**: the pristine `phoenix` entity accepts only a PS/2 keyboard
  scancode stream — its `kbd_joystick`/`io_ps2_keyboard` instances and the
  resulting `coin`/`player_start`/`buttons` signals
  (`phoenix.vhd:429-436`/original numbering) are entirely internal, with no
  ports to intercept for a JA joystick or dedicated buttons (unlike every
  other machine in this project). **Resolved** (user-confirmed, second
  blocking decision beyond the video one): applied
  `contrib/code/phoenix_expose_control_ports.patch`, adding
  `ext_coin`/`ext_start1`/`ext_start2`/`ext_fire`/`ext_right`/`ext_left`/
  `ext_up` ports to the `phoenix` entity, OR-merged with the existing
  `JoyPCFRLDU`-derived signals (`coin <= not JoyPCFRLDU(7) or ext_coin`,
  etc.) — PS/2 keyboard input keeps working unmodified. This is the second
  pristine-file functionality patch in this port (after none needed for
  video — the separator lives entirely in the wrapper). The Basys3 wrapper
  drives the `ext_*` ports from JA (active-low, inverted) and dedicated
  buttons: `buttons(0)`=fire (JA(4)), `buttons(1)`=right (JA(0)),
  `buttons(2)`=left (JA(1)), `buttons(3)`=up/shield (JA(3));
  `player_start(0)`=start1 (btnL), `player_start(1)`=start2 (btnR);
  `coin`=btnU. JA(2) (down) is present on the connector but unused — the
  game has no down input.
- **`audio_select` needs a wider switch range than the Makefile originally
  documented**: the `phoenix` entity's `audio_select` port is 3 bits
  (`std_logic_vector(2 downto 0)`) — `"100"`/`"101"`/`"110"`/`"111"` select
  effect1/effect2/effect3/melody solo, anything else (`"000"`-`"011"`) mixes
  all four; a 2-bit switch range can't reach the MSB-gated solo selections.
  **Resolved**: wired `audio_select <= sw(10 downto 8)` (3 bits; `sw(10)` is
  otherwise unused on this board), Makefile `IO_SUMMARY` updated to match.
- **`sw(14)`/`sw(15)` naming**: the Makefile's `IO_SUMMARY` originally said
  `sw(14)=shutdown`, `sw(15)=gain` — functionally the fleet's
  sound-enable/AMP-gain pair (root `README.md` §"Common Basys 3 platform":
  `sw14` = sound enable, `sw15` = AMP gain), just named differently.
  **Resolved**: `IO_SUMMARY` wording aligned; the underlying signal
  connections are unchanged (`O_PMODAMP2_SHUTD <= sw(14)`,
  `O_PMODAMP2_GAIN <= sw(15)`, same as every other machine).
- **Audio**: reuse the pristine DE10 top's 13-bit PWM accumulator verbatim
  (`pwm_accumulator <= unsigned('0' & pwm_accumulator(11 downto 0)) +
  unsigned(audio & '0')`, `audio` is 12 bits) — same pattern as every other
  machine in this project (each reuses its own core's native accumulator
  width/slicing rather than a shared implementation).
- **Debug hex display**: not ported (no Basys3 board in this repo carries
  7-segment wiring) — matches every other machine.
- **LEDs**: the pristine top's `ledr(8 downto 0) <= "101010101"` is a static
  debug pattern, not meaningfully core-driven; omit the `led` port entirely
  (matches Bagman/Pooyan/Time-Pilot/Berzerk/Burnin-Rubber's convention).
- **`btnD`**: this port declares no `btnD` (only one coin button is needed,
  unlike Burnin-Rubber's dual coin buttons). `contrib/basys3/vivado/Basys-3-Master.xdc`'s
  `btnD` constraint is commented out for this machine (matches Bagman's
  convention of trimming each machine's own XDC copy to the ports it
  actually declares — an unconstrained-but-XDC-referenced port produces a
  `CRITICAL WARNING: 'set_property' expects at least one object`, not a
  fatal error, but is worth avoiding).

## Open design questions

1. **Unverified until hardware bring-up**: the ~32 µs / 176-cycle /
   ~54 µs / 300-cycle sync-separator thresholds are a design estimate from
   `phoenix_video.vhd`'s pulse-width comments, not cross-checked
   pixel-by-pixel against its `hcnt`/`vcnt` compare values, and the
   separator itself has no Dar reference to validate against. Plan B if it
   does not lock: patch `phoenix_video.vhd` to expose real hsync/vsync from
   `hcnt`/`vcnt` (see "Video path" above).
