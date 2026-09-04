# Traverse-USA-by-Dar — Porting spec

## 1. Reference model

- Source archive: `vhdl_traverse_usa_rev_0_0_2019_03_16.zip` (SourceForge
  folder `traverse_usa`) → `vhdl_traverse_usa_rev_0_0_2019_03_16/` at the
  machine root.
- Core: `rtl_dar/traverse_usa.vhd` (entity `traverse_usa`); off-core support
  `rtl_dar/{moon_patrol_sound_board,gen_ram,io_ps2_keyboard,kbd_joystick}.vhd`,
  `rtl_jkent/cpu68.vhd` (M6803), `rtl_mikej/ym_2149_linmix.vhd`, `rtl_T80/*`.
- Top entity: `traverse_usa_basys3` (target file
  `sources_1/new/traverse_usa_basys3.vhd`).
- Part: `xc7a35tcpg236-1`, VHDL target language.
- Status: in progress (see root `README.md` Status section for the current
  verified stage).

## 2. Clocking

- Two core clocks: **36.86 MHz** (`clock_36`, core) and **3.58 MHz**
  (`clock_3p58`, sound board), derived on DE10-lite from 50 MHz by
  `max10_pll_36p86M_3p58M`. On Basys 3, `clk_wiz_0` derives both from the
  100 MHz board oscillator (single MMCM, two outputs).
- Reset active-high (`btnC`), `locked` used — see §3.
- The pristine top also derives a divided `clock_6` (a toggle) for the
  keyboard via a `clock_div` mod-6 counter on `clock_36`; this divider is
  reused verbatim (renamed `clock_kbd` to avoid colliding with the
  scandoubler's `sd_clock_6`).

## 3. Reset polarity

- **Basys 3:** `reset <= btnC or not mmcm_locked;` (Bagman/Berzerk/Pooyan
  pattern) — core held in reset while `btnC` is pressed or the MMCM has not
  locked. `clk_wiz_0`'s own `reset` port is driven directly by `btnC`.

## 4. Video (31 kHz VGA / 15 kHz TV, switch-selectable)

The `traverse_usa` core entity declares `video_hs`/`video_vs` output ports but
the shipped core leaves the drivers **commented out** (the pristine DE10 top
also leaves them `open`, with a "not tested" comment) — only `video_csync` is
active. This core therefore belongs in the **Phoenix/Xevious/Zaxxon category**
("core needs a patch to expose hsync/vsync before a scandoubler can be used").

`contrib/code/traverse_usa_expose_video_timing.patch` un-comments the dormant
drivers — no new logic needed:

```vhdl
video_hs <= hsync0;
if    vsync_cnt = 0 then video_vs <= '0';
elsif vsync_cnt = 8 then video_vs <= '1';
end if;
```

`video_hs` is the core's real per-line `hsync0` pulse (already valid
horizontal sync, unconditional every line). `video_vs` is built from the
existing `vsync_cnt` variable — a 4-bit feedback counter that the
composite-sync generator already runs (it counts 0→F and is reset at line
start): `video_vs` is low only while `vsync_cnt = 0`, high otherwise, giving a
1-line vertical-sync pulse inside the existing blanking window (the same
`vsync_cnt = 8` pulse-width convention Burnin-Rubber uses). Deliberately
independent of the legacy equalizing/serration machinery that drives
`video_csync`.

No `line_doubler.vhd` exists in this core's archive (that's
Bagman/Berzerk's structurally different no-scandoubler approach), and the
wrapper is not inside the core, so the patch is the only viable fix — matching
the Phoenix/Xevious/Zaxxon signature (no `tv15Khz_mode` input, no internal
`line_doubler`) from the `xpr-dependency-closure` skill's classification
table.

### Scandoubler clocks

The core's pixel clock is 6.14 MHz (`pix_ena`-equivalent; the core's real
video rate is `clock_36 / 6`). The wrapper derives `sd_clock_12`
(`clk_sys`) and `sd_clock_6` (`ce_x1`) with a mod-6 counter on `clock_36`,
following **Galaga's proven pattern** — Galaga's own porting record
(`Galaga-Midway-by-Dar/PORTING_SPEC.md` #12.3.3) documents that wiring a fast
MMCM clock directly to `clk_sys` "no funciona" (does not work); the working
design uses a derived `clk_sys` at 2× `ce_x1`, with `ce_x2` tied to `'1'`.
This port follows Burnin-Rubber-by-Dar's scan-doubler wiring shape directly.

The imported `scandoubler.v` is the MiST scandoubler
(`contrib/code/scandoubler.v`, cleanroom import, never modified in place),
added under `imports/mist/`. `contrib/code/scandoubler_fix.patch` (Vivado
2020.2 Verilog-2001 parser fix) is applied only to the copied project
instance by `create_project.sh`, never to the canonical import.

### Component declaration (as declared in `traverse_usa_basys3.vhd`)

```vhdl
component scandoubler
    port (
        clk_sys   : in  std_logic;
        scanlines : in  std_logic_vector (1 downto 0);
        ce_x1     : in  std_logic;
        ce_x2     : in  std_logic;
        hs_in     : in  std_logic;
        vs_in     : in  std_logic;
        r_in      : in  std_logic_vector (5 downto 0);
        g_in      : in  std_logic_vector (5 downto 0);
        b_in      : in  std_logic_vector (5 downto 0);
        hs_out    : out std_logic;
        vs_out    : out std_logic;
        r_out     : out std_logic_vector (5 downto 0);
        g_out     : out std_logic_vector (5 downto 0);
        b_out     : out std_logic_vector (5 downto 0)
    );
end component;
```

Binds by name to the Verilog module `scandoubler`, `COLOR_DEPTH = 6` /
`HCNT_WIDTH = 9` defaults, not overridden.

### Port map (`scandoubler_inst`)

| Port | Direction | Connected signal | Type/width |
|---|---|---|---|
| `clk_sys` | in | `sd_clock_12` (derived, see above) | `std_logic` |
| `scanlines` | in | `"00"` (literal) | `std_logic_vector(1 downto 0)` |
| `ce_x1` | in | `sd_clock_6` (derived) | `std_logic` |
| `ce_x2` | in | `'1'` (literal) | `std_logic` |
| `hs_in` | in | `hsync` (core `video_hs`) | `std_logic` |
| `vs_in` | in | `vsync` (core `video_vs`) | `std_logic` |
| `r_in` | in | `vga_r_i` | `std_logic_vector(5 downto 0)` |
| `g_in` | in | `vga_g_i` | `std_logic_vector(5 downto 0)` |
| `b_in` | in | `vga_b_i` | `std_logic_vector(5 downto 0)` |
| `hs_out` | out | `hsync_o` | `std_logic` |
| `vs_out` | out | `vsync_o` | `std_logic` |
| `r_out` | out | `vga_r_o` | `std_logic_vector(5 downto 0)` |
| `g_out` | out | `vga_g_o` | `std_logic_vector(5 downto 0)` |
| `b_out` | out | `vga_b_o` | `std_logic_vector(5 downto 0)` |

### Upstream signals (into the scan doubler)

- `hs_in`/`vs_in`: driven directly by the core's `video_hs`/`video_vs`
  outputs (real only since `traverse_usa_expose_video_timing.patch`, see
  above), no intermediate logic. `video_csync` is not connected to the scan
  doubler; it drives the local `csync` used only by the `sw(13)` TV-mode
  output mux.
- `r_in`/`g_in`/`b_in`: the core exposes native `r`/`g`/`b` as 2/3/3 bits
  (`video_r(1:0)`, `video_g(2:0)`, `video_b(2:0)`) plus a `blankn`
  (`video_blankn`) output. Padded to 6 bits by MSB replication, forced to
  `"000000"` while blanked:

  ```vhdl
  vga_r_i <= r & r & r      when blankn = '1' else "000000";
  vga_g_i <= g & g           when blankn = '1' else "000000";
  vga_b_i <= b & b           when blankn = '1' else "000000";
  ```
- `scanlines`: tied to `"00"` (scanline attenuation unused).

### Downstream signals (out of the scan doubler) — `sw(13)` mux

- **VGA mode (`sw(13) = '0'`)** — 31 kHz progressive VGA, sync from the scan
  doubler, colour truncated to the top 4 bits of each 6-bit field:
  ```vhdl
  vgaHsync <= hsync_o;  vgaVsync <= vsync_o;
  vgaRed   <= vga_r_o(5 downto 2);
  vgaGreen <= vga_g_o(5 downto 2);
  vgaBlue  <= vga_b_o(5 downto 2);
  ```
- **TV mode (`sw(13) = '1'`)** — 15 kHz TV, native core RGB (2/3/3 padded to
  4/4/4 with zeros), composite sync on HS, VS held high:
  ```vhdl
  vgaRed <= r & "00";  vgaGreen <= g & '0';  vgaBlue <= b & '0';
  vgaHsync <= csync;  vgaVsync <= '1';
  ```

### Caveats

- The pristine DE10-lite top leaves `video_hs`/`video_vs` unconnected and
  derives all sync from `video_csync` only — and the shipped core doesn't
  drive `video_hs`/`video_vs` without `traverse_usa_expose_video_timing.patch`.
  This port wires the patched signals into the scan doubler; a pattern not
  validated on real hardware in the original Dar release for this core.

## 5. Audio (mono PWM on PmodAMP2)

- `audio_out` is 11-bit on this core (`audio(10:0)`), mono — matching the
  Burnin-Rubber note's "11-bit mono `audio_out`" case.
- The PWM accumulator is reused verbatim from the pristine DE10 top
  (`pwm_accumulator <= ( '0' & pwm_accumulator(11 downto 0) ) +
  ( audio & "00" )`, 13-bit accumulator, `O_PMODAMP2_AIN <=
  pwm_accumulator(12)`), clocked on `clock_3p58` (same clock as the
  `moon_patrol_sound_board`).
- `sw(15)` → AMP gain, `sw(14)` → AMP shutdown (standard convention).

## 6. Inputs

- **Keyboard is always on the Basys 3 onboard USB HID host** (C17 =
  `ps2_clk`, B17 = `ps2_dat`) — plugged into the onboard USB-A port, never
  JB and never an external PS/2 connector. This follows the Computer-Space /
  Congo Bongo convention (as opposed to Galaga/Popeye/Tron/Defender, which
  put the keyboard on JB), feeding the standard `io_ps2_keyboard`/
  `kbd_joystick` chain.
- **The keyboard sampling clock must be ≥ 6 MHz** (verified working rate on
  the Basys3 onboard USB-HID host). The pristine top's mod-6 toggle on
  `clock_36` (~3 MHz) leaves the onboard USB-HID port non-functional (the
  same symptom Arcade_Zaxxon and Congo Bongo hit and fixed, confirmed on
  real hardware 2026-09-03; Pooyan's working design also uses ~6 MHz).
  This port's `clock_kbd` is a **keyboard-only** divider (nothing shares
  `clock_div` here — the PWM accumulator runs on `clock_3p58`, so changing
  its period has no audio side effect) set to a mod-3 toggle →
  `clock_36/6 ≈ 6.14 MHz`. See the machine `README.md` Known issues.
- The `kbd_joystick` used here is the `joyPCFRLDU` (8-bit) variant in this
  core's archive (not `joy_BBBBFRLDU`): bit0=Up, bit1=Down, bit2=Left,
  bit3=Right, bit4=Space, bit5=F1, bit6=F2, bit7=F3.
- JA joystick (5-pin, active-low, invert to active-high) OR-merged into
  movement + accelerate/brake only: `JA1=Right, JA2=Left, JA3=Down/brake,
  JA4=Up/accelerate, JA7=Fire/accelerate`. **The core has no genuine fire
  input** (`traverse_usa.vhd` port list has no `fire`) — accelerate and fire
  both drive the core's `accel` port. So up (JA4, or arrow-UP bit0) *and*
  fire (JA7, or SPACE bit4) both accelerate, and down (JA3, or arrow-DOWN
  bit1) brakes.
- **Coin/start: dedicated Basys3 buttons** in addition to the keyboard:
  `btnU`/`btnD` = coin (both map to the core's single `coin1`), `btnL` =
  start 1, `btnR` = start 2, each OR'd with the keyboard-decoded
  `joyPCFRLDU(5)`/`(6)`/`(7)` (F1/F2/F3). No JA combos are added: this port
  has dedicated buttons, so the combo layer is redundant.
- Player 2 mirrors player 1 movement inputs (the core has no genuine second
  control set, only cocktail-mode duplicates — matches the pristine top,
  which wired `right2`/`left2`/`brake2`/`accel2` to the same P1 joystick
  bits).
- Dip switches are hardcoded to `x"FF"` / `x"FE"` (same constants as the
  pristine DE10 top).

## 7. LEDs

- No `led` port: the pristine top's `ledr` and 7-segment `hex0..3` are a
  debug/`dbg_cpu_addr` chain not ported (matches every other machine's
  convention); `dbg_cpu_addr` is left `open`.

## 8. Synthesis-fix / behavior-fix patches

- `traverse_usa_expose_video_timing.patch`: un-comments the core's dormant
  `video_hs`/`video_vs` drivers (see §4) — a behavior fix, not a
  synthesis-failure fix; the pristine core synthesizes without error but
  produces no valid VGA sync.
- `scandoubler_fix.patch` (§4) is applied to the imported scandoubler copy
  only, not to the pristine `traverse_usa` tree.
- No width/sensitivity synthesis-fix patch was needed for this core.

## 9. Shared conventions & hard rules

- **Non-nested project layout**: the `.xpr` lives directly in `basys3/` as
  `basys3/traverse_usa_basys3.xpr`, sources tree at
  `basys3/traverse_usa_basys3.srcs/`.
- **Vivado build scripts run from `/tmp`** so `vivado.log`/`vivado.jou` stay
  out of the repo.
- **Tool/path resolution** is `ENV_VAR → project default → interactive prompt`:
  - Vivado: `VIVADO` → `/tools/Xilinx/Vivado/2020.2/bin/vivado`
  - roms: `ROMZIP` → `~/roms/travrusa.zip`
- **Roms and generated PROM VHDL are copyrighted content** — never commit or
  distribute them.
