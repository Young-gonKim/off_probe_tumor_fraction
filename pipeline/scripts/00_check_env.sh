#!/bin/bash
# Verify that everything the pipeline needs is present. Run this first.
set -uo pipefail
source "$(dirname "$0")/../config/settings.env"
fail=0
say(){ printf '%-46s %s\n' "$1" "$2"; }
for t in bwa samtools Rscript; do
  if command -v $t >/dev/null 2>&1; then say "$t" "OK  $(command -v $t)"
  else say "$t" "MISSING (install it and re-run)"; fail=1; fi
done
[ -x "$READCOUNTER" ] && say "readCounter (bundled)" "OK" || { say "readCounter (bundled)" "MISSING/not executable"; fail=1; }
for f in "$PROBE_REF" "$PROBE_REF.bwt" "$GC_WIG" "$MAP_WIG" "$CENTROMERE" "$PON_V1" "$RUNNER"; do
  [ -s "$f" ] && say "$(basename "$f")" "OK" || { say "$(basename "$f")" "MISSING: $f"; fail=1; }
done
# The v2 panel of normals is only needed for TSO500 v2 samples, which are the
# default for unlabelled projects — missing is a warning, not a failure.
if [ -s "$PON_V2" ]; then say "$(basename "$PON_V2")" "OK"
else say "$(basename "$PON_V2")" "MISSING - v2 samples cannot run (scripts/04_build_v2_pon.sh)"; fi
# offline UCSC chrom-info mirror (GenomeInfoDb cannot reach hgdownload.ucsc.edu
# from every host; see scripts/offline_cache.R)
for f in "$PIPE_ROOT/scripts/offline_cache.R" \
         "$PIPE_ROOT/reference/ucsc_goldenPath/hg19/database/chromInfo.txt.gz"; do
  [ -s "$f" ] && say "$(basename "$f")" "OK" || { say "$(basename "$f")" "MISSING: $f"; fail=1; }
done

# BSgenome.Hsapiens.UCSC.hg19 is deliberately NOT checked and not shipped: no script
# in this bundle loads it (chromosome lengths come from the offline goldenPath mirror),
# and it is 771 MB. If something ever needs it, install it separately.
rpkgs=$(Rscript -e '.libPaths(c(Sys.getenv("RLIB"), .libPaths()));
  for (p in c("optparse","ichorCNA","HMMcopy","GenomicRanges","GenomeInfoDb",
              "plyr","foreach","doMC","ggplot2"))
    cat(sprintf("%-46s %s\n", p, if (requireNamespace(p, quietly=TRUE)) "OK" else "MISSING"))' 2>&1 | grep -v '^$')
echo "$rpkgs"
echo "$rpkgs" | grep -q 'MISSING' && fail=1
echo
[ $fail -eq 0 ] && echo "environment OK" || { echo "environment INCOMPLETE - see MISSING above"; exit 1; }
