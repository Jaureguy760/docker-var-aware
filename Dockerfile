ARG BASE_IMAGE=pytorch/pytorch:2.5.1-cuda12.1-cudnn9-runtime
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive \
    CONDA_ROOT=/opt/conda \
    MAMBA_ROOT_PREFIX=/opt/conda \
    MAMBA_NO_BANNER=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    NUMBA_CACHE_DIR=/tmp/numba-cache \
    HF_HOME=/tmp/huggingface \
    TRANSFORMERS_CACHE=/tmp/huggingface/transformers \
    HUGGINGFACE_HUB_CACHE=/tmp/huggingface/hub \
    RUNNER_CONDA_ENV=ipscs-gvl

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bedtools \
    build-essential \
    ca-certificates \
    curl \
    git \
    tini \
    && rm -rf /var/lib/apt/lists/*

RUN conda install -n base -c conda-forge mamba -y && conda clean -afy

WORKDIR /opt/runner
COPY install_runai_ipscs_gvl_env.sh /opt/runner/install_runai_ipscs_gvl_env.sh
COPY runner-entrypoint.sh /usr/local/bin/runner-entrypoint.sh

RUN chmod +x /opt/runner/install_runai_ipscs_gvl_env.sh /usr/local/bin/runner-entrypoint.sh \
    && RUNAI_INSTALL_FLASH_ATTN=1 RUNAI_TORCH_CUDA_ARCH_LIST=8.6 /opt/runner/install_runai_ipscs_gvl_env.sh ipscs-gvl \
    && conda clean -afy \
    && rm -rf /root/.cache/pip

RUN groupadd -g 1000 runner && useradd -m -u 1000 -g runner runner \
    && mkdir -p /workspace /tmp/numba-cache /tmp/huggingface \
    && chown -R runner:runner /workspace /tmp/numba-cache /tmp/huggingface

USER runner
WORKDIR /workspace
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/runner-entrypoint.sh"]
