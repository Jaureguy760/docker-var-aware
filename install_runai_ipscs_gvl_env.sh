#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-${RUNNER_CONDA_ENV:-ipscs-gvl}}"
RECREATE="${RUNAI_RECREATE_ENV:-0}"
INSTALL_FLASH_ATTN="${RUNAI_INSTALL_FLASH_ATTN:-1}"
TORCH_CUDA_ARCH_LIST_VALUE="${RUNAI_TORCH_CUDA_ARCH_LIST:-8.6}"
CONDA_ROOT="${CONDA_ROOT:-/opt/conda}"

if [[ -f "${CONDA_ROOT}/etc/profile.d/conda.sh" ]]; then
    set +u
    # shellcheck disable=SC1091
    source "${CONDA_ROOT}/etc/profile.d/conda.sh"
    set -u
else
    echo "FATAL: conda.sh not found under ${CONDA_ROOT}" >&2
    exit 1
fi

if command -v mamba >/dev/null 2>&1; then
    SOLVER=(mamba)
else
    SOLVER=(conda)
fi

env_exists=0
if conda env list | awk '{print $1}' | grep -Fxq "${ENV_NAME}"; then
    env_exists=1
fi

if [[ "${env_exists}" == "1" && "${RECREATE}" == "1" ]]; then
    "${SOLVER[@]}" env remove -n "${ENV_NAME}" -y
    env_exists=0
fi

if [[ "${env_exists}" == "0" ]]; then
    "${SOLVER[@]}" create -n "${ENV_NAME}" -y \
        python=3.10 \
        pip \
        setuptools \
        wheel \
        packaging=24.2 \
        pytorch \
        torchvision \
        torchaudio \
        pytorch-cuda=12.1 \
        lightning=2.4.0 \
        cuda-nvcc=12.9 \
        gcc_linux-64=11 \
        gxx_linux-64=11 \
        'cmake>=3.26' \
        ninja \
        'polars>=1.4' \
        wandb \
        bitsandbytes \
        'einops>=0.8' \
        bcftools \
        samtools \
        tabix \
        htslib \
        -c pytorch -c nvidia -c conda-forge -c bioconda
fi

set +u
conda activate "${ENV_NAME}"
set -u

pip install --no-cache-dir \
    peft==0.15.2 \
    transformers==4.52.0 \
    genvarloader==0.17.0 \
    'seqpro>=0.4.0' \
    borzoi-pytorch \
    bpnet-lite==0.8.1 \
    DCLS

if [[ "${INSTALL_FLASH_ATTN}" == "1" ]]; then
    export CUDA_HOME="${CONDA_PREFIX}"
    export FORCE_CUDA=1
    export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST_VALUE}"
    # Prefer prebuilt wheel (avoids compiling CUDA kernels under QEMU cross-build).
    # Falls back to source build if no compatible wheel is found.
    if ! pip install flash-attn==2.7.2.post1 --no-cache-dir 2>/dev/null; then
        echo "INFO: No prebuilt wheel for flash-attn 2.7.2.post1, building from source..." >&2
        pip install flash-attn==2.7.2.post1 --no-build-isolation --no-cache-dir
    fi
fi
