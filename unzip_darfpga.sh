#!/usr/bin/env bash
# Unzip the DarFPGA archives from downloads/ into their per-game directories
# and apply each game's fix patch (where one exists).
#
# Usage:
#   ./unzip_darfpga.sh [--force] [ZIPDIR]
# Default ZIPDIR is "<script dir>/downloads". Existing unzipped trees are
# skipped unless --force is given; patches use -N so an already-applied patch
# is detected and skipped rather than failing.
set -euo pipefail

# game_dir|zip_file|fix_patch (patch may be empty)
GAMES=(
  "Bagman-FPGA-Dar|vhdl_bagman_rev_0_1_2018_06_05.zip|bagman_xor_width.patch"
  "Berzerk-FPGA-by-Dar|vhdl_berzerk_rev_0_1_2018_08_08.zip|berzerk_reset_sensitivity.patch"
  "Burnin-Rubber-by-Dar|vhdl_burnin_rubber_rev_0_0_2017_12_22.zip|"
  "Galaga-Midway-by-Dar|vhdl_galaga_rev_0_3_2018_05_06.zip|galaga_credit_mode_fix.patch"
  "Kick-Midway-MCR-by-Dar|vhdl_kick_rev_0_2_2019_11_22.zip|"
  "Pooyan-by-Dar|vhdl_pooyan_rev_0_2_2020_04_26.zip|pooyan_t80_xor_width.patch"
  "Popeye-by-Dar|vhdl_popeye_rev_0_3_2020_01_27.zip|popeye_linmix_sensitivity.patch"
  "Sky-skipper-by-Dar|vhdl_sky_skipper_rev_01_2020_01_28.zip|"
  "Solar-Fox-by-Dar|vhdl_solar_fox_rev_0_1_2019_11_22.zip|"
  "Time-Pilot-by-Dar|vhdl_time_pilot_rev_0_0_2017_11_05.zip|"
)

FORCE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIPDIR="$SCRIPT_DIR/downloads"
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) ZIPDIR="$arg" ;;
  esac
done

command -v unzip >/dev/null 2>&1 || { echo "error: unzip not found" >&2; exit 1; }
command -v patch >/dev/null 2>&1 || { echo "error: patch not found" >&2; exit 1; }

ok=0
skip=0
fail=0
for entry in "${GAMES[@]}"; do
  IFS='|' read -r game zip patch <<< "$entry"
  zipfile="$ZIPDIR/$zip"
  gamedir="$SCRIPT_DIR/$game"
  srcroot="$(basename "$zip" .zip)" # top-level dir the zip extracts to

  if [[ ! -s "$zipfile" ]]; then
    echo "error: $zip not found in $ZIPDIR (run download_darfpga.sh?)" >&2
    fail=$((fail + 1))
    continue
  fi
  mkdir -p "$gamedir"

  if [[ -d "$gamedir/$srcroot" && $FORCE -eq 0 ]]; then
    echo "skip   $game (already unzipped)"
    skip=$((skip + 1))
    continue
  fi

  echo "unzip  $game"
  unzip -q "$zipfile" -d "$gamedir"

  if [[ -n "$patch" && -f "$gamedir/$patch" ]]; then
    echo "patch  $game with $patch"
    patch -p1 -N -d "$gamedir" < "$gamedir/$patch"
  fi
  ok=$((ok + 1))
done

echo "----------------------------------------"
echo "processed: $ok, skipped: $skip, failed: $fail"
[[ $fail -eq 0 ]]
