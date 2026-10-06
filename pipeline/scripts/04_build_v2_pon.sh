#!/bin/bash
# Build the TSO500 **v2** panel of normals at the frozen flank of 50 bp.
#
#   04_build_v2_pon.sh [--bam-dir DIR] [--work DIR] [--jobs N] [--threads N]
#
# Source data: the 10 normals sequenced on TSO500 v2 chemistry,
#   <bam-dir>/research{19,21,26,29,34,48,53,54,57,58}_tumor.bam
# (a PoN built at any other flank is NOT usable here: this bundle is frozen at
#  flank 50 and a flank/PoN mismatch fails silently.)
#
# Output: pon/pon_v2_non_amplified_flank50.rds_median.rds  (+ _median.txt, members list)
#
# Cost: a full bwa realignment of ~100 GB of BAM. Hours, not minutes.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../config/settings.env"

BAM_DIR=${V2_BAM_DIR:-}
WORK=${WORK:-$PWD/pon_build_flank${FLANK}}
JOBS=5
THREADS=16

while [ $# -gt 0 ]; do
  case "$1" in
    --bam-dir) BAM_DIR=$2; shift 2 ;;
    --work)    WORK=$2;    shift 2 ;;
    --jobs)    JOBS=$2;    shift 2 ;;
    --threads) THREADS=$2; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BAM_DIR" ] || { echo "ERROR: pass --bam-dir (or set V2_BAM_DIR)" >&2; exit 2; }
mapfile -t BAMS < <(ls "$BAM_DIR"/*.bam 2>/dev/null | grep -v '\.md5sum$' | sort)
[ ${#BAMS[@]} -gt 0 ] || { echo "ERROR: no BAMs in $BAM_DIR" >&2; exit 1; }
echo "v2 normals: ${#BAMS[@]}"

mkdir -p "$WORK"
# --- 1. off-target wigs at flank $FLANK, $JOBS samples at a time ------------
for BAM in "${BAMS[@]}"; do
  S=$(basename "$BAM" .bam)
  W="$WORK/${S}_non_amplified_flank${FLANK}.wig"
  if [ -s "$W" ]; then echo "  [skip] $S (wig exists)"; continue; fi
  while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do wait -n || true; done
  echo "  [run ] $S"
  "$HERE/01_extract_offtarget.sh" "$BAM" "$WORK" "$THREADS" \
    > "$WORK/${S}_flank${FLANK}.log" 2>&1 &
done
wait || true   # a failed sample is reported by the missing-wig check below

# --- 2. member list --------------------------------------------------------
LIST="$HERE/../pon/pon_v2_flank${FLANK}_members.txt"
: > "$LIST"
for BAM in "${BAMS[@]}"; do
  S=$(basename "$BAM" .bam)
  W="$WORK/${S}_non_amplified_flank${FLANK}.wig"
  [ -s "$W" ] || { echo "ERROR: missing wig for $S (see $WORK/${S}_flank${FLANK}.log)" >&2; exit 1; }
  echo "$W" >> "$LIST"
done
echo "members -> $LIST ($(wc -l < "$LIST") wigs)"

# --- 3. the PoN itself -----------------------------------------------------
# --minMapScore 0.9 matches the bundled v1 PoN (2,594 bins). Omitting it uses the
# createPanelOfNormals default of 0.0 and yields 2,956 bins — a PoN that does not
# line up with how 02_run_ichorCNA.sh filters bins.
PREFIX="$HERE/../pon/pon_v2_non_amplified_flank${FLANK}.rds"
Rscript "$HERE/createPoN_v060.R" \
  --filelist "$LIST" --gcWig "$GC_WIG" --mapWig "$MAP_WIG" \
  --centromere "$CENTROMERE" --minMapScore 0.9 --outfile "$PREFIX"
echo "built ${PREFIX}_median.rds"
