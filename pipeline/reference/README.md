# Reference files (hg19)

| file | source |
|---|---|
| `gc_hg19_1000kb.wig`, `map_hg19_1000kb.wig` | ichorCNA v0.6.0 `inst/extdata`, unchanged — GPL-3.0 (`LICENSE.GPL-3`), not MIT |
| `centromere_hg19.txt` | ichorCNA v0.6.0 `inst/extdata` |
| `ucsc_goldenPath/hg19/database/chromInfo.txt.gz` | UCSC hg19 chromosome table, local copy so GenomeInfoDb need not download it (`scripts/offline_cache.R`) |

Not included — build locally:

| file | how |
|---|---|
| target BED | your own capture-target BED (for TSO500, the manifest Illumina supplies with the assay) |
| `target_sequences_flank50.fasta` (+ bwa index) | `scripts/00_build_probe_reference.sh <targets.bed> hg19.fa 50` |

The Illumina TSO500 manifest is not redistributed in this repository.
