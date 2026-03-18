# docker-var-aware

Private standalone image-build repo for the varAware / FlashZoi RunAI baseline.

This repo builds a baked `linux/amd64` CUDA/PyTorch image with the exact
`ipscs-gvl` environment preinstalled, so RunAI jobs do not need to solve conda
or install packages at runtime.

## Platform

- Your local MacBook M3 is `arm64`
- The RunAI cluster is `Linux x86_64`
- Build target must be `linux/amd64`

Recommended:

- build in GitHub Actions, or
- build locally with Docker Buildx and `--platform linux/amd64`

## Image contents

The baked image installs:

- `python=3.10.16`
- `pytorch=2.5.1`
- `torchvision=0.20.1`
- `torchaudio=2.5.1`
- `pytorch-cuda=12.1`
- `pytorch-lightning=2.3.3`
- `torchmetrics=1.6.1`
- `packaging=24.2`
- `genvarloader==0.17.0`
- `seqpro==0.7.1`
- `borzoi-pytorch==0.4.1`
- `bpnet-lite==0.8.1`
- `DCLS==0.1.1`
- `wandb==0.20.1`
- `einops==0.8.0`
- `peft==0.15.2`
- `transformers==4.36.2`
- `flash-attn==2.6.3`

The runtime entrypoint activates `ipscs-gvl` automatically and executes
`RUNNER_CMD`.

## Build in GitHub Actions

Push to `main`, or run the workflow manually.

Published image:

```bash
ghcr.io/jaureguy760/docker-var-aware-baseline:<tag>
```

Example:

```bash
gh workflow run build-image.yml -f tag=2026-03-18
```

## Build locally on an M3 Mac

Use Docker Buildx:

```bash
bash ./build_image.sh 2026-03-18
```

That builds and pushes:

```bash
ghcr.io/jaureguy760/docker-var-aware-baseline:2026-03-18
```

## Run locally

```bash
docker run --rm -it \
  -e RUNNER_CMD='python -c "import torch, lightning, genvarloader, seqpro, borzoi_pytorch, flash_attn; print(\"ok\")"' \
  ghcr.io/jaureguy760/docker-var-aware-baseline:2026-03-18
```

## Run on RunAI

Use the image with the mounted repo and a simple `RUNNER_CMD`.

Example:

```bash
runai training standard submit flashzoi-smoke \
  -p mcvicker-lab \
  --node-pools default \
  --priority medium-high \
  --image ghcr.io/jaureguy760/docker-var-aware-baseline:2026-03-18 \
  --gpu-devices-request 1 \
  --cpu-core-request 12 \
  --cpu-core-limit 12 \
  --cpu-memory-request 96Gi \
  --cpu-memory-limit 96Gi \
  --host-path path=/iblm/netapp/data3/jjaureguy/gvl_files/varAware,mount=/workspace,readwrite \
  --restart-policy Never \
  --backoff-limit 0 \
  --wait-for-submit 5m \
  --environment-variable RUNNER_CMD='cd /workspace && python /workspace/paper_results/prediction_generation/coverage_predictions/generate_flashzoi_zeroshot_ddp.py --gvl_path /workspace/gvl_datasets/new/ipscs_Flashzoi_v14.gvl --reference /workspace/iPSCORE_files/shared_files/hg38.fa.gz --test_samples_txt /workspace/paper_results/results/runai_validation/inputs/run_flashzoi_zeroshot_predictions/test_samples_ref_smoke.txt --output_dir /workspace/evaluation/predictions/flashzoi/ref_zeroshot_chr1/stage_smoke --batch_size 1 --devices 1 --use_ref --chunk_size 512 --resume'
```

## Important note about private GHCR images

This repo is private because you asked for a private repo. That means the GHCR
package will also be private by default.

If the cluster cannot pull private GHCR images anonymously, you must do one of:

- make the package public, or
- configure RunAI / Kubernetes image pull credentials for `ghcr.io`
