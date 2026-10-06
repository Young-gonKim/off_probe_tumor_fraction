# ---------------------------------------------------------------------------
# offline_cache.R
#
# GenomeInfoDb resolves hg19 chromosome names/lengths by downloading
#   <UCSC.goldenPath.url>/hg19/database/chromInfo.txt.gz
# from hgdownload*.ucsc.edu. On hosts without access to UCSC that download
# fails and ichorCNA::getSeqInfo() aborts before any model is fitted.
#
# This file points GenomeInfoDb at a local copy of that table, shipped in
#   reference/ucsc_goldenPath/hg19/database/chromInfo.txt.gz
# (generated from BSgenome.Hsapiens.UCSC.hg19, i.e. the same UCSC assembly),
# and warms the in-session cache. The NCBI half of the mapping
# (getChromInfoFromNCBI) is bundled inside GenomeInfoDb and needs no network.
#
# Chromosome names and lengths are identical to the UCSC download, so results
# are unchanged; only the source of the table differs.
#
# Sourced by scripts/runIchorCNA_v060.R when present. Override the location
# with $UCSC_GOLDENPATH_DIR if you keep the mirror somewhere else.
# ---------------------------------------------------------------------------

local({
  dir <- Sys.getenv("UCSC_GOLDENPATH_DIR")
  if (!nzchar(dir)) {
    here <- dirname(normalizePath(sub("^--file=", "",
              grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1])))
    dir <- file.path(dirname(here), "reference", "ucsc_goldenPath")
  }
  if (!dir.exists(dir)) {
    message("offline_cache.R: no local goldenPath mirror at ", dir,
            " - falling back to the UCSC download")
    return(invisible(NULL))
  }
  # GenomeInfoDb's .onLoad sets UCSC.goldenPath.url, so load it *first*.
  suppressPackageStartupMessages(library(GenomeInfoDb))
  options(UCSC.goldenPath.url = paste0("file://", normalizePath(dir)))
  ok <- try(GenomeInfoDb::getChromInfoFromUCSC("hg19", map.NCBI = TRUE), silent = TRUE)
  if (inherits(ok, "try-error"))
    stop("offline_cache.R: local goldenPath mirror at ", dir,
         " could not be read:\n", ok)
  cat("### offline chrom-info mirror:", getOption("UCSC.goldenPath.url"), "\n")
})
