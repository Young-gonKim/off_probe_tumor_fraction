#!/bin/bash
# ONLY needed if you are moving to a different capture kit or flank.
# TSO500 v1 -> reuse the bundled pon/pon_v1_17_non_amplified_flank50.rds_median.rds as is.
#              (17 normals; one degenerate member removed 2026-09-10 — see ../CHANGELOG.md)
# TSO500 v2 -> use scripts/04_build_v2_pon.sh, which wraps this step around the 10
#              v2 normals (--bam-dir) and passes
#              --minMapScore 0.9 (this script does not).
#
#   03_build_new_pon.sh <wig_list.txt> <output_prefix>
#
# wig_list.txt: one flank-50 normal wig path per line, produced by 01_extract_offtarget.sh.
# A PoN must ALWAYS be built at the same flank as the samples it will normalise.
set -euo pipefail
source "$(dirname "$0")/../config/settings.env"
LIST=$1; PREFIX=$2
Rscript "$(dirname "$0")/createPoN_v060.R" \
  --filelist "$LIST" --gcWig "$GC_WIG" --mapWig "$MAP_WIG" \
  --centromere "$CENTROMERE" --outfile "$PREFIX"
echo "built ${PREFIX}_median.rds"
