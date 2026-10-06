#!/bin/bash
# Panel-of-normals selection by TSO500 assay version. Sourced, not executed.
#
# TSO500 v1 samples must be normalised against the bundled v1 PoN (17 normals since
# 2026-09-10, when one degenerate member was removed);
# TSO500 v2 samples against PoN_V2 (10 normals
# sequenced on v2 chemistry,
# see scripts/04_build_v2_pon.sh). Normalising v2 data against the v1
# PoN is a silent failure — no error, just a biased tumour fraction — which is why
# resolve_pon() refuses to guess when a path says one thing and $PANEL_VERSION
# says another.
#
# Precedence:
#   1. $PON set explicitly in the environment           -> used as is
#   2. $PANEL_VERSION (settings.env, env var, --v1/--v2) -> that version's PoN
#   3. a v1/v2 path component of the input file          -> that version's PoN
#   4. $PANEL_VERSION_DEFAULT (v2)                       -> new/unlabelled projects

# detect_panel_version <path> -> prints v1 | v2 | (nothing)
detect_panel_version() {
  local p
  p=$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')
  local hit_v1=0 hit_v2=0
  [[ $p =~ (^|[^a-z0-9])v1([^a-z0-9]|$) ]] && hit_v1=1
  [[ $p =~ (^|[^a-z0-9])v2([^a-z0-9]|$) ]] && hit_v2=1
  # a v2 PoN sample lives under .../rawdata/v2/V2_PoN/ — both tokens are v2 there,
  # so only an actual v1+v2 collision is ambiguous
  if [ $hit_v1 -eq 1 ] && [ $hit_v2 -eq 1 ]; then
    echo "WARNING: '$1' contains both v1 and v2; not inferring a version from it" >&2
    return 0
  fi
  [ $hit_v1 -eq 1 ] && { echo v1; return 0; }
  [ $hit_v2 -eq 1 ] && { echo v2; return 0; }
  return 0
}

# resolve_pon <input path>
# Sets PON, PANEL_VERSION and PON_SOURCE (how the choice was made).
resolve_pon() {
  local input=${1:-} inferred
  inferred=$(detect_panel_version "$input")

  if [ -n "${PON:-}" ]; then
    PON_SOURCE="explicit \$PON"
    PANEL_VERSION=${PANEL_VERSION:-unknown}
  elif [ -n "${PANEL_VERSION:-}" ]; then
    PON_SOURCE="PANEL_VERSION=$PANEL_VERSION"
    if [ -n "$inferred" ] && [ "$inferred" != "$PANEL_VERSION" ]; then
      echo "ERROR: PANEL_VERSION=$PANEL_VERSION but the input path looks like $inferred:" >&2
      echo "       $input" >&2
      echo "       Refusing to guess. Fix the path or the version." >&2
      return 1
    fi
  elif [ -n "$inferred" ]; then
    PANEL_VERSION=$inferred
    PON_SOURCE="assay version inferred from the input path"
  else
    PANEL_VERSION=${PANEL_VERSION_DEFAULT:-v2}
    PON_SOURCE="default for unlabelled projects (PANEL_VERSION_DEFAULT)"
  fi

  if [ -z "${PON:-}" ]; then
    case "$PANEL_VERSION" in
      v1) PON=$PON_V1 ;;
      v2) PON=$PON_V2 ;;
      *)  echo "ERROR: PANEL_VERSION must be v1 or v2, got '$PANEL_VERSION'" >&2; return 1 ;;
    esac
  fi

  # flank/PoN mismatch is the pipeline's worst silent failure: catch it here.
  case "$(basename "$PON")" in
    *flank"${FLANK}".*) : ;;
    *) echo "ERROR: PoN $(basename "$PON") is not flank-matched to FLANK=$FLANK." >&2
       echo "       Build one at flank $FLANK (scripts/03_build_new_pon.sh, or" >&2
       echo "       scripts/04_build_v2_pon.sh for the v2 panel) before running." >&2
       return 1 ;;
  esac

  if [ ! -s "$PON" ]; then
    echo "ERROR: PoN not found: $PON" >&2
    [ "$PANEL_VERSION" = v2 ] && \
      echo "       Build it with: scripts/04_build_v2_pon.sh" >&2
    return 1
  fi
  export PON PANEL_VERSION PON_SOURCE
}
