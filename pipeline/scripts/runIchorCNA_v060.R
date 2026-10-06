#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# CLI wrapper for ichorCNA v0.6.0 (GavinHaLab).
#
# v0.6.0 ships no standalone scripts/runIchorCNA.R any more; the entry point is
# the exported R function ichorCNA::run_ichorCNA(). This wrapper reproduces the
# familiar command-line interface so the same driver shell scripts used for the
# FINAL2 (ichorCNA v0.3.2) analysis can be reused.
#
# Every default below is copied verbatim from the run_ichorCNA() function
# signature at tag v0.6.0 (commit be6d599). Nothing is silently overridden:
# if an option is not given on the command line, run_ichorCNA()'s own default
# is what gets used.
# ---------------------------------------------------------------------------

# relocatable: use $RLIB if set, else <bundle>/Rlib next to this script
.libPaths(c(if (nzchar(Sys.getenv("RLIB"))) Sys.getenv("RLIB") else file.path(dirname(dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1])))), "Rlib"), .libPaths()))

suppressPackageStartupMessages({
  library(optparse)
})

option_list <- list(
  # ---- inputs ----
  make_option("--WIG",           type = "character", default = NULL,   help = "Path to tumour WIG file. Required."),
  make_option("--NORMWIG",       type = "character", default = NULL,   help = "Path to normal WIG file."),
  make_option("--gcWig",         type = "character", default = NULL,   help = "Path to GC-content WIG file. Required."),
  make_option("--mapWig",        type = "character", default = NULL,   help = "Path to mappability score WIG file."),
  make_option("--repTimeWig",    type = "character", default = NULL,   help = "Path to replication timing WIG file."),
  make_option("--normalPanel",   type = "character", default = NULL,   help = "Median corrected depth from panel of normals (.rds)."),
  make_option("--sex",           type = "character", default = NULL,   help = "User specified sex: male or female."),
  make_option("--exons.bed",     type = "character", default = NULL,   help = "Path to bed file containing exon regions."),
  make_option("--id",            type = "character", default = "test", help = "Patient ID. [%default]"),
  make_option("--centromere",    type = "character", default = NULL,   help = "Centromere locations file; package hg19 file if NULL."),
  # ---- filtering ----
  make_option("--minMapScore",   type = "numeric",   default = 0.9,    help = "Minimum mappability score. [%default]"),
  make_option("--flankLength",   type = "numeric",   default = 1e5,    help = "Length of region flanking centromere to remove. [%default]"),
  # ---- model initialisation ----
  make_option("--normal",        type = "character", default = "0.5",  help = "Initial normal contamination. [%default]"),
  make_option("--normal.init",   type = "character", default = "c(0.5, 0.5)", help = "Normal init for multiple samples. [%default]"),
  make_option("--scStates",      type = "character", default = "NULL", help = "Subclonal states to consider. [%default]"),
  make_option("--scPenalty",     type = "numeric",   default = 0.1,    help = "Penalty for subclonal state transitions. [%default]"),
  make_option("--normal2IgnoreSC", type = "numeric", default = 1.0,    help = "Ignore subclonal analysis above this normal proportion. [%default]"),
  make_option("--coverage",      type = "numeric",   default = NULL,   help = "PICARD sequencing coverage."),
  make_option("--likModel",      type = "character", default = "t",    help = "Likelihood model: t or gaussian. [%default]"),
  make_option("--lambda",        type = "character", default = "NULL", help = "Initial Student's t precision."),
  make_option("--lambdaScaleHyperParam", type = "numeric", default = 3, help = "Gamma prior scale on Student's-t precision. [%default]"),
  make_option("--kappa",         type = "character", default = "50",   help = "Initial state distribution. [%default]"),
  make_option("--ploidy",        type = "character", default = "2",    help = "Initial tumour ploidy. [%default]"),
  make_option("--maxCN",         type = "numeric",   default = 7,      help = "Total clonal CN states. [%default]"),
  # ---- estimation switches ----
  make_option("--estimateNormal",       type = "logical", default = TRUE, help = "Estimate normal. [%default]"),
  make_option("--estimateScPrevalence", type = "logical", default = TRUE, help = "Estimate subclonal prevalence. [%default]"),
  make_option("--estimatePloidy",       type = "logical", default = TRUE, help = "Estimate tumour ploidy. [%default]"),
  make_option("--maxFracCNASubclone",   type = "numeric", default = 0.7, help = "Max fraction of subclonal CNA events. [%default]"),
  make_option("--maxFracGenomeSubclone", type = "numeric", default = 0.5, help = "Max subclonal genome fraction. [%default]"),
  make_option("--minSegmentBins",       type = "numeric", default = 50,  help = "Min bins in largest segment to estimate TF. [%default]"),
  make_option("--altFracThreshold",     type = "numeric", default = 0.05, help = "Min proportion of altered bins to estimate TF. [%default]"),
  # ---- chromosomes / genome ----
  make_option("--chrNormalize",  type = "character", default = "c(1:22)", help = "Chromosomes to normalize GC/map biases. [%default]"),
  make_option("--chrTrain",      type = "character", default = "c(1:22)", help = "Chromosomes used to estimate params. [%default]"),
  make_option("--chrs",          type = "character", default = "c(1:22,\"X\")", help = "Chromosomes to analyze. [%default]"),
  make_option("--genomeBuild",   type = "character", default = "hg19", help = "Genome build. [%default]"),
  make_option("--genomeStyle",   type = "character", default = "NCBI", help = "NCBI or UCSC chromosome naming. [%default]"),
  make_option("--normalizeMaleX", type = "logical",  default = TRUE,   help = "If male, normalize chrX by median. [%default]"),
  make_option("--fracReadsInChrYForMale", type = "numeric", default = 0.001, help = "chrY read fraction threshold for male. [%default]"),
  make_option("--includeHOMD",   type = "logical",   default = FALSE,  help = "Include HOMD state. [%default]"),
  # ---- HMM transitions ----
  make_option("--txnE",          type = "numeric",   default = 0.9999999, help = "Self-transition probability. [%default]"),
  make_option("--txnStrength",   type = "numeric",   default = 1e7,    help = "Transition pseudo-counts. [%default]"),
  make_option("--multSampleTxnStrength", type = "numeric", default = 1, help = "Same-state transition strength between samples. [%default]"),
  # ---- output ----
  make_option("--plotFileType",  type = "character", default = "pdf",  help = "Plot file format. [%default]"),
  make_option("--plotYLim",      type = "character", default = "c(-2,2)", help = "Ylim for chromosome plots. [%default]"),
  make_option("--outDir",        type = "character", default = "./",   help = "Output directory. [%default]"),
  make_option("--cores",         type = "numeric",   default = 1,      help = "Number of cores for EM. [%default]")
)

parseobj <- OptionParser(option_list = option_list)
opt <- parse_args(parseobj)

if (is.null(opt$WIG))   stop("--WIG is required")
if (is.null(opt$gcWig)) stop("--gcWig is required")

# optparse cannot express an unquoted NULL; map the literal strings through.
nullify <- function(x) if (is.null(x) || identical(x, "NULL") || identical(x, "None")) NULL else x

dir.create(opt$outDir, recursive = TRUE, showWarnings = FALSE)

cat("### ichorCNA wrapper: package version",
    as.character(packageVersion("ichorCNA")),
    "from", find.package("ichorCNA"), "\n")
cat("### effective options ###\n")
for (n in names(opt)) {
  if (n == "help") next
  cat(sprintf("  %-24s = %s\n", n,
              if (is.null(opt[[n]])) "NULL" else paste(as.character(opt[[n]]), collapse = ",")))
}
cat("### running ichorCNA::run_ichorCNA() ###\n")
flush(stdout())

suppressPackageStartupMessages(library(GenomeInfoDb))
# offline_cache.R was sourced from an absolute path on the build machine and is
# not part of this bundle. Source it only if it is actually present: either at
# $OFFLINE_CACHE, or next to this script. Otherwise continue without it.
local({
  cand <- c(Sys.getenv("OFFLINE_CACHE"),
            file.path(dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1]))), "offline_cache.R"))
  cand <- cand[nzchar(cand) & file.exists(cand)]
  if (length(cand)) { cat("### sourcing offline cache:", cand[1], "\n"); source(cand[1]) }
})
suppressPackageStartupMessages(library(ichorCNA))

run_ichorCNA(
  tumor_wig             = opt$WIG,
  normal_wig            = nullify(opt$NORMWIG),
  gcWig                 = opt$gcWig,
  mapWig                = nullify(opt$mapWig),
  repTimeWig            = nullify(opt$repTimeWig),
  normal_panel          = nullify(opt$normalPanel),
  sex                   = nullify(opt$sex),
  exons.bed             = nullify(opt[["exons.bed"]]),
  id                    = opt$id,
  centromere            = nullify(opt$centromere),
  minMapScore           = opt$minMapScore,
  flankLength           = opt$flankLength,
  normal                = opt$normal,
  normal.init           = opt[["normal.init"]],
  scStates              = opt$scStates,
  scPenalty             = opt$scPenalty,
  normal2IgnoreSC       = opt$normal2IgnoreSC,
  coverage              = nullify(opt$coverage),
  likModel              = opt$likModel,
  lambda                = nullify(opt$lambda),
  lambdaScaleHyperParam = opt$lambdaScaleHyperParam,
  kappa                 = as.numeric(opt$kappa),
  ploidy                = opt$ploidy,
  maxCN                 = opt$maxCN,
  estimateNormal        = opt$estimateNormal,
  estimateScPrevalence  = opt$estimateScPrevalence,
  estimatePloidy        = opt$estimatePloidy,
  maxFracCNASubclone    = opt$maxFracCNASubclone,
  maxFracGenomeSubclone = opt$maxFracGenomeSubclone,
  minSegmentBins        = opt$minSegmentBins,
  altFracThreshold      = opt$altFracThreshold,
  chrNormalize          = opt$chrNormalize,
  chrTrain              = opt$chrTrain,
  chrs                  = opt$chrs,
  genomeBuild           = opt$genomeBuild,
  genomeStyle           = opt$genomeStyle,
  normalizeMaleX        = opt$normalizeMaleX,
  fracReadsInChrYForMale = opt$fracReadsInChrYForMale,
  includeHOMD           = opt$includeHOMD,
  txnE                  = opt$txnE,
  txnStrength           = opt$txnStrength,
  multSampleTxnStrength = opt$multSampleTxnStrength,
  plotFileType          = opt$plotFileType,
  plotYLim              = opt$plotYLim,
  outDir                = opt$outDir,
  cores                 = opt$cores
)

cat("### ichorCNA DONE:", opt$id, "###\n")
