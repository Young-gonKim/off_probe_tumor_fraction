# ---------------------------------------------------------------------------
# Put the pipeline's own runtime on PATH.  Source it, do not execute it:
#
#     source <repo>/pipeline/activate.sh
#
# Sets PIPE_ROOT, prepends the bundled conda environment (bwa 0.7.17,
# samtools 1.21, R 4.3.3 + ichorCNA dependencies) to PATH, and points the
# scripts at the bundled R library and the offline UCSC chrom-info mirror.
#
# Nothing here is an analysis setting; those live in config/settings.env and
# are unchanged.
# ---------------------------------------------------------------------------
_pipe_self="${BASH_SOURCE[0]:-$0}"
export PIPE_ROOT="$(cd "$(dirname "$_pipe_self")" && pwd)"
export PIPE_ENV="${PIPE_ENV:-$PIPE_ROOT/env}"
[ -d "$PIPE_ENV/bin" ] && export PATH="$PIPE_ENV/bin:$PATH"   # optional bundled env; otherwise use the conda env from environment.yml
export RLIB="$PIPE_ROOT/Rlib"
export UCSC_GOLDENPATH_DIR="$PIPE_ROOT/reference/ucsc_goldenPath"
export PIPE_VERSION="$(cat "$PIPE_ROOT/VERSION" 2>/dev/null || echo unknown)"
echo "TSO500 off-probe pipeline v$PIPE_VERSION  ($PIPE_ROOT)"
unset _pipe_self
