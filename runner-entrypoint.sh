#!/usr/bin/env bash

set -euo pipefail

CONDA_ROOT="${CONDA_ROOT:-/opt/conda}"
export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-${CONDA_ROOT}}"
export MAMBA_NO_BANNER=1
export NUMBA_CACHE_DIR="${NUMBA_CACHE_DIR:-/tmp/numba-cache}"
export HF_HOME="${HF_HOME:-/tmp/huggingface}"
export TRANSFORMERS_CACHE="${TRANSFORMERS_CACHE:-${HF_HOME}/transformers}"
export HUGGINGFACE_HUB_CACHE="${HUGGINGFACE_HUB_CACHE:-${HF_HOME}/hub}"
export PIP_DISABLE_PIP_VERSION_CHECK=1

mkdir -p "${NUMBA_CACHE_DIR}" "${HF_HOME}" "${TRANSFORMERS_CACHE}" "${HUGGINGFACE_HUB_CACHE}"

if [[ -f "${CONDA_ROOT}/etc/profile.d/conda.sh" ]]; then
    set +u
    # shellcheck disable=SC1091
    source "${CONDA_ROOT}/etc/profile.d/conda.sh"
    set -u
else
    echo "FATAL: conda.sh not found under ${CONDA_ROOT}" >&2
    exit 1
fi

if [[ -n "${RUNNER_CONDA_ENV:-}" ]]; then
    set +u
    conda activate "${RUNNER_CONDA_ENV}"
    set -u
fi

if [[ -z "${RUNNER_CMD:-}" ]]; then
    exec /bin/bash
fi

exec /bin/bash -lc -- "${RUNNER_CMD}"
