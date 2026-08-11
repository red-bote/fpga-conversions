#!/usr/bin/env bash
# Download the DarFPGA (darfpga) source archives for the arcade games ported
# in this workspace, from:
#   https://sourceforge.net/projects/darfpga/files/Software%20VHDL/
#
# Usage:
#   ./download_darfpga.sh [OUTDIR]
# Default OUTDIR is "<script dir>/downloads". Existing files are skipped
# unless --force is given.
set -euo pipefail

BASE="https://sourceforge.net/projects/darfpga/files/Software%20VHDL"

# name|sf_folder|zip_file
PROJECTS=(
  "bagman|bagman|vhdl_bagman_rev_0_1_2018_06_05.zip"
  "berzerk|berzerk|vhdl_berzerk_rev_0_1_2018_08_08.zip"
  "burnin_rubber|burnin_rubber|vhdl_burnin_rubber_rev_0_0_2017_12_22.zip"
  "galaga|galaga|vhdl_galaga_rev_0_3_2018_05_06.zip"
  "kick|Kick_kickman|vhdl_kick_rev_0_2_2019_11_22.zip"
  "pooyan|pooyan|vhdl_pooyan_rev_0_2_2020_04_26.zip"
  "popeye|popeye|vhdl_popeye_rev_0_3_2020_01_27.zip"
  "sky_skipper|sky_skipper|vhdl_sky_skipper_rev_01_2020_01_28.zip"
  "solar_fox|Solarfox|vhdl_solar_fox_rev_0_1_2019_11_22.zip"
  "time_pilot|time_pilot|vhdl_time_pilot_rev_0_0_2017_11_05.zip"
)

FORCE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="$SCRIPT_DIR/downloads"
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) OUTDIR="$arg" ;;
  esac
done
mkdir -p "$OUTDIR"

command -v curl >/dev/null 2>&1 || { echo "error: curl not found" >&2; exit 1; }

ok=0
fail=0
for entry in "${PROJECTS[@]}"; do
  IFS='|' read -r name sf_folder zip <<< "$entry"
  url="$BASE/$sf_folder/$zip/download"
  dest="$OUTDIR/$zip"

  if [[ -s "$dest" && $FORCE -eq 0 ]]; then
    echo "skip   $name ($zip already present)"
    ok=$((ok + 1))
    continue
  fi

  echo "fetch  $name"
  if curl -L --fail --retry 3 --output "$dest" "$url"; then
    # SourceForge mirrors can return an HTML error page despite --fail; verify
    # it is actually a zip before counting it as a success.
    if [[ "$(head -c2 "$dest")" != "PK" ]]; then
      echo "error: $zip is not a zip archive (HTML mirror page?)" >&2
      rm -f "$dest"
      fail=$((fail + 1))
      continue
    fi
    echo "  saved $dest"
    ok=$((ok + 1))
  else
    echo "error: failed to download $name" >&2
    rm -f "$dest"
    fail=$((fail + 1))
  fi
done

echo "----------------------------------------"
echo "downloaded/skipped: $ok, failed: $fail"
[[ $fail -eq 0 ]]
