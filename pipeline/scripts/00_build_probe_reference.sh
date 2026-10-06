#!/bin/bash
# Build the bwa-indexed probe reference that 01_extract_offtarget.sh aligns against:
# every capture target in your target BED, extended by FLANK bp on each side.
#
#   00_build_probe_reference.sh <targets.bed> <hg19.fa> [flank] [outdir]
#
# targets.bed  : YOUR capture-target BED, chr-prefixed hg19 coordinates, columns
#                chrom / start (0-based) / end / [name]. For TSO500 this is the target
#                manifest supplied by Illumina with the assay (not redistributed here);
#                any other hybrid-capture panel's target BED works the same way.
# hg19.fa      : UCSC hg19 FASTA with a .fai index (samtools faidx hg19.fa).
#
# Output: <outdir>/target_sequences_flank<F>.fasta (+ bwa index). Each record is
#   >chrN:<start-F>-<end+F>, <name>
# i.e. the 1-based closed interval [start-F, end+F], matching the record headers of the
# reference used for the published analysis.
#
# Note: the published reference was built by an earlier script that also wrote the
# source FASTA path as a line inside every record. This script omits that line, so the
# result is not byte-identical; the genomic sequences are the same.
set -euo pipefail
BED=$1; FA=$2; FLANK=${3:-50}; OUTDIR=${4:-$(dirname "$0")/../reference}
[ -s "$FA.fai" ] || samtools faidx "$FA"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/target_sequences_flank${FLANK}.fasta"

awk -v F="$FLANK" 'BEGIN{OFS="\t"} !/^(#|track|browser)/ && NF>=3 {
  s = $2 - F; if (s < 1) s = 1
  print $1 ":" s "-" ($3 + F), ($4 == "" ? "." : $4)
}' "$BED" > "$OUT.regions.tsv"

: > "$OUT"
while IFS=$'\t' read -r REGION NAME; do
  samtools faidx "$FA" "$REGION" | sed "1s|.*|>$REGION, $NAME|" >> "$OUT"
done < "$OUT.regions.tsv"
rm -f "$OUT.regions.tsv"

echo "records: $(grep -c '^>' "$OUT")"
bwa index "$OUT"
echo "done -> $OUT"
