#!/bin/sh
# Auto-scale thread-related env vars to available CPUs for interactive shells.
# Users can override by setting variables explicitly via `docker run -e`.

if command -v nproc >/dev/null 2>&1; then
  N=$(nproc)
else
  N=1
fi

# Only set if not already provided
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-$N}"
export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-$N}"
export MKL_NUM_THREADS="${MKL_NUM_THREADS:-$N}"
export NUMEXPR_NUM_THREADS="${NUMEXPR_NUM_THREADS:-$N}"
export OPENBLAS_VERBOSE=0
