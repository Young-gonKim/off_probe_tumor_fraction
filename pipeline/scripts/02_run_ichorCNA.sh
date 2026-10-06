#!/bin/bash
# Estimate tumour fraction from a flank-50 wig, against the flank-50 PoN that
# matches the TSO500 assay version of the sample.
#
#   02_run_ichorCNA.sh [--v1|--v2] <sample_non_amplified_flank50.wig> <outdir>
#
# v1 wigs are normalised against the bundled v1 PoN (17 normals), v2 wigs against
# PoN_V2 (10 v2 normals). With no flag the version is taken from a v1/v2 component
# of the wig path, and failing that from PANEL_VERSION_DEFAULT (v2). See
# scripts/lib_pon.sh.
set -euo pipefail
# 2026-09-10: --txnE/--txnStrength previously carried ichorCNA's *snakemake config*
# values (0.9999 / 1e4), not the defaults of run_ichorCNA() itself (0.9999999 / 1e7),
# and --normal2IgnoreSC was left at the wrapper's 1.0 instead of the 0.9 that
# getDefaultParameters() sets. Restoring all three drops the limit of blank from
# 4.28% to 1.74% on 10 healthy donors. See ../CHANGELOG.md.
source "$(dirname "$0")/../config/settings.env"
source "$(dirname "$0")/lib_pon.sh"

while [ $# -gt 0 ]; do
  case "$1" in
    --v1|--v2) PANEL_VERSION=${1#--}; shift ;;
    --panel-version) PANEL_VERSION=$2; shift 2 ;;
    *) break ;;
  esac
done
WIG=$1; OUTDIR=$2
ID=$(basename "$WIG" .wig)

# the wig path is what identifies the assay version; fall back to the outdir
SRC=$WIG
if [ -z "$(detect_panel_version "$WIG")" ]; then SRC=$OUTDIR; fi
resolve_pon "$SRC"
echo "TSO500 $PANEL_VERSION  ->  PoN $(basename "$PON")   [$PON_SOURCE]"

mkdir -p "$OUTDIR"
Rscript "$RUNNER" \
  --id "$ID" --WIG "$WIG" --outDir "$OUTDIR" \
  --gcWig "$GC_WIG" --mapWig "$MAP_WIG" --normalPanel "$PON" \
  --centromere "$CENTROMERE" --repTimeWig None \
  --normal "$NORMAL_GRID" \
  --ploidy "c(2,3)" --maxCN 5 --scStates "c(1,3)" \
  --txnE 0.9999999 --txnStrength 1e7 --normal2IgnoreSC 0.9 --includeHOMD False \
  --estimateNormal True --estimatePloidy True --estimateScPrevalence True \
  --maxFracGenomeSubclone 0.5 --maxFracCNASubclone 0.7 \
  --minMapScore 0.9 --fracReadsInChrYForMale 0.001 --normalizeMaleX True \
  --chrs "paste0('chr', c(1:22, \"X\"))" --chrTrain "paste0('chr', c(1:22))" \
  --genomeBuild "$GENOME_BUILD" --genomeStyle "$GENOME_STYLE" \
  --plotFileType pdf --plotYLim "c(-2,2)"
P=$(ls "$OUTDIR/$ID"/solution_optimal_*/"$ID".params.txt 2>/dev/null | head -1)
if [ -s "$P" ]; then
  awk -F'\t' 'NR==2{printf "tumour fraction: %s   ploidy: %s\n", $2, $3}' "$P"
  echo "full output: $(dirname "$P")"
else
  echo "ERROR: no optimal solution written under $OUTDIR/$ID" >&2; exit 1
fi
