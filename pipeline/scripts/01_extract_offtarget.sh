#!/bin/bash
# Remove probe-derived reads at the frozen flank of 50 bp and produce a 1 Mb wig.
#
#   01_extract_offtarget.sh <input.bam> <outdir> [threads]
#
# input.bam must be aligned to GRCh37/hg19 with 'chr'-prefixed contig names and indexed.
# Output: <outdir>/<sample>_non_amplified_flank50.{bam,bam.bai,wig}
set -euo pipefail
source "$(dirname "$0")/../config/settings.env"
IN=$1; OUTDIR=$2; TH=${3:-8}
SAMPLE=$(basename "$IN" .bam)
mkdir -p "$OUTDIR"
IDS="$OUTDIR/${SAMPLE}.probe_ids.txt"
OUT_BAM="$OUTDIR/${SAMPLE}_non_amplified_flank${FLANK}.bam"
WIG="$OUTDIR/${SAMPLE}_non_amplified_flank${FLANK}.wig"

echo "[1/4] realigning reads to the flank-${FLANK} probe reference"
samtools fasta -@ "$TH" "$IN" 2>/dev/null \
  | bwa mem -M -p -t "$TH" "$PROBE_REF" - 2>/dev/null \
  | awk '!/^@/ && NF>=10 && $6 ~ /M/ {print $1}' \
  | sort -u --parallel="$TH" -S 2G > "$IDS"
echo "      probe-derived read names: $(wc -l < "$IDS")"

echo "[2/4] removing them from the original BAM"
samtools view -@ "$TH" -N "$IDS" -U "$OUT_BAM" -o /dev/null "$IN"

echo "[3/4] indexing"
samtools index -@ "$TH" "$OUT_BAM"

echo "[4/4] binning at ${BIN_SIZE} bp"
"$READCOUNTER" --window "$BIN_SIZE" --quality "$MAPQ" --chromosome "$CHROMS" "$OUT_BAM" > "$WIG"

rm -f "$IDS"
echo "done -> $WIG"
