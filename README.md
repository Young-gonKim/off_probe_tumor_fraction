# Off-probe tumour fraction from TSO500 targeted sequencing

Code accompanying:

> **Tumour fraction from the off-target coverage of a targeted sequencing panel.**
> _Authors_. _Journal_ (_year_). doi: _TBD_

The pipeline estimates circulating tumour fraction (TF) from TruSight Oncology 500
(TSO500) hybrid-capture data with no additional sequencing. It removes probe-derived
reads at the **read level** (each read is re-aligned to the capture-target sequences
extended by 50 bp, and every read that maps there is discarded), bins the remaining
genome-wide off-target coverage at 1 Mb, and runs
[ichorCNA](https://github.com/GavinHaLab/ichorCNA) v0.6.0 against a flank-matched
panel of normals.

```
TSO500 BAM ──► re-align to targets ±50 bp ──► drop probe reads ──► 1 Mb wig ──► ichorCNA ──► TF
             (01_extract_offtarget.sh)                          (readCounter) (02_run_ichorCNA.sh)
```

Contents:

| folder | what it is |
|---|---|
| [`pipeline/`](pipeline) | The packaged pipeline (v2.1) — use this to estimate TF on your own TSO500 BAMs. |

Only what is needed to run the algorithm is distributed. No sequencing data, per-sample
results or clinical information are included; the panels of normals are shipped as
per-bin median coverage only (no individual-level data).

---

## 1. Installation

Linux x86-64. All dependencies are in bioconda / conda-forge:

```bash
conda env create -f environment.yml
conda activate offprobe-tf
```

Then install ichorCNA v0.6.0 (GPL-3; not redistributed here) into that environment:

```bash
git clone https://github.com/GavinHaLab/ichorCNA.git
git -C ichorCNA checkout be6d5999          # tag v0.6.0
R CMD INSTALL ichorCNA
```

Check the environment:

```bash
source pipeline/activate.sh
bash pipeline/scripts/00_check_env.sh      # last line must read 'environment OK'
```

### Probe reference (one-time) — bring your own target BED

The Illumina TSO500 target manifest is **not** distributed in this repository. Instead,
`00_build_probe_reference.sh` builds the probe reference from **your own capture-target
BED** (for TSO500, the manifest supplied by Illumina with the assay; any other
hybrid-capture panel's target BED works the same way) and a UCSC hg19 FASTA:

```bash
bash pipeline/scripts/00_build_probe_reference.sh /path/to/targets.bed /path/to/hg19.fa 50
#   -> pipeline/reference/target_sequences_flank50.fasta (+ bwa index)
```

With a panel other than TSO500, also build a panel of normals from your own normal
samples (`03_build_new_pon.sh`); the bundled panels are TSO500-specific.

## 2. Usage

Input BAMs must be aligned to **GRCh37/hg19 with `chr`-prefixed contigs**, coordinate
sorted and indexed. A BAM that is not will produce TF = 0 for every sample without an
error.

```bash
source pipeline/activate.sh

# stage 1: remove probe-derived reads and bin at 1 Mb   (~20-40 min per BAM, 8 threads)
bash pipeline/scripts/01_extract_offtarget.sh sample.bam wig/ 8

# stage 2: tumour fraction                              (~1-2 min)
bash pipeline/scripts/02_run_ichorCNA.sh --v1 wig/sample_non_amplified_flank50.wig out/
#   prints:  tumour fraction: <TF>   ploidy: <ploidy>
```

`--v1` / `--v2` selects the panel of normals for the TSO500 chemistry version:

| assay | panel of normals (`pipeline/pon/`) | members |
|---|---|---|
| TSO500 v1 | `pon_v1_17_non_amplified_flank50.rds_median.rds` | 17 (2 healthy donors + 15 MSAF = 0 plasma) |
| TSO500 v2 | `pon_v2_non_amplified_flank50.rds_median.rds` | 10 healthy donors |

For another capture panel, build a panel of normals **at the same flank** from your own
normal samples with `pipeline/scripts/03_build_new_pon.sh`. A flank / panel mismatch
produces biased estimates without an error; `02_run_ichorCNA.sh` refuses to run one.

All frozen analysis settings are in `pipeline/config/settings.env`; the exact ichorCNA
argument list is in `pipeline/config/ichorCNA_params_v2.1.txt`. Every ichorCNA argument
is a package default or a value distributed with ichorCNA.

## Dependencies and versions used

| software | version |
|---|---|
| ichorCNA | v0.6.0 (GavinHaLab, commit `be6d5999`) |
| HMMcopy utils `readCounter` | 0.1.1 |
| bwa | 0.7.17-r1188 |
| samtools | 1.21 |
| R | 4.3.3 (GenomicRanges 1.54.1, GenomeInfoDb 1.38.1, optparse 1.7.5) |

Reference: hg19. 1 Mb GC and mappability wigs from ichorCNA `inst/extdata`; centromere
table from the UCSC hg19 gap table (all included in `pipeline/reference/`).

## Citation

If you use this code, please cite the paper above and ichorCNA
(Adalsteinsson _et al._, _Nat Commun_ 2017; 8:1324). See [`CITATION.cff`](CITATION.cff).

## License

MIT — see [`LICENSE`](LICENSE).

Exception: `pipeline/reference/gc_hg19_1000kb.wig` and `map_hg19_1000kb.wig` are copied
unchanged from ichorCNA v0.6.0 and remain under GPL-3.0
([`pipeline/reference/LICENSE.GPL-3`](pipeline/reference/LICENSE.GPL-3)). ichorCNA itself
(GPL-3) is a separately installed dependency and is not redistributed here.

## Contact

_Corresponding author_, _email_
