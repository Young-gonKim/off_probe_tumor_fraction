# Changelog

Tumour fractions from different major versions are not comparable; re-run every sample
after an upgrade.

## 2.1 — 2026-09-11 (version used in the paper)

- The tumour-fraction initialisation grid returns to ichorCNA's distributed
  `--normal c(0.5,0.6,0.7,0.8,0.9,0.95)`. v2.0 added a seventh start at `0.99`.
  Across 11 flank sizes and 60 development samples the two grids give the same Spearman
  correlation with lcWGS to four decimals at flanks 20–100. It was removed because an
  initialisation grid extended toward the tumour-free end can only move the reported
  solution toward near-zero, so it is a study-introduced parameter acting on the
  quantity being measured.
- No ichorCNA argument now deviates from the package as distributed.

## 2.0 — 2026-09-10

- `--txnE 0.9999999 --txnStrength 1e7 --normal2IgnoreSC 0.9`, the defaults of
  `ichorCNA::run_ichorCNA()`. 1.0 used ichorCNA's snakemake-config values
  (`0.9999 / 1e4`, `normal2IgnoreSC` 1.0), a transition prior 1000× weaker than the
  package intends. On ten healthy-donor blanks this lowers the limit of blank from
  4.28 % to 1.74 %.
- TSO500 v1 panel of normals 18 → 17 members. One member converged to a degenerate
  solution (TF 1.0, ploidy 0.92) under every configuration tested.
- TSO500 v2 panel of normals (10 healthy donors) added; `--v1` / `--v2` selects the panel.

## 1.0 — 2026-08-25

First packaged release.
