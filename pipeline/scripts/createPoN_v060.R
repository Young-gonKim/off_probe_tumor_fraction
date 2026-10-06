#!/usr/bin/env Rscript
# CLI wrapper for ichorCNA v0.6.0 createPanelOfNormals(), which the release ships
# only as an R function. Defaults copied verbatim from the function signature.
# relocatable: use $RLIB if set, else <bundle>/Rlib next to this script
.libPaths(c(if (nzchar(Sys.getenv("RLIB"))) Sys.getenv("RLIB") else file.path(dirname(dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1])))), "Rlib"), .libPaths()))
suppressPackageStartupMessages(library(optparse))
option_list <- list(
  make_option("--filelist",   type="character"),
  make_option("--outfile",    type="character"),
  make_option("--gcWig",      type="character"),
  make_option("--mapWig",     type="character", default=NULL),
  make_option("--centromere", type="character", default=NULL),
  make_option("--flankLength",type="numeric",   default=1e5),
  make_option("--chrs",       type="character", default="c(1:22,\"X\")"),
  make_option("--genomeStyle",type="character", default="NCBI"),
  make_option("--genomeBuild",type="character", default="hg19"),
  make_option("--chrNormalize",type="character",default="c(1:22)"),
  make_option("--minMapScore",type="numeric",   default=0.0),
  make_option("--method",     type="character", default="median")
)
opt <- parse_args(OptionParser(option_list=option_list))
suppressPackageStartupMessages(library(GenomeInfoDb))
# offline_cache.R was sourced from an absolute path on the build machine and is
# not part of this bundle; source it only if present (see runIchorCNA_v060.R).
local({
  cand <- c(Sys.getenv("OFFLINE_CACHE"),
            file.path(dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1]))), "offline_cache.R"))
  cand <- cand[nzchar(cand) & file.exists(cand)]
  if (length(cand)) source(cand[1])
})
suppressPackageStartupMessages(library(ichorCNA))
createPanelOfNormals(gcWig=opt$gcWig, mapWig=opt$mapWig, filelist=opt$filelist,
  outfile=opt$outfile, centromere=opt$centromere, flankLength=opt$flankLength,
  chrs=opt$chrs, genomeStyle=opt$genomeStyle, genomeBuild=opt$genomeBuild,
  chrNormalize=opt$chrNormalize, minMapScore=opt$minMapScore, method=opt$method)
cat("### PoN DONE:", opt$outfile, "###\n")
