#!/usr/bin/env bash

set -euo pipefail

TAG="${1:-$(date +%Y-%m-%d)}"
IMAGE="ghcr.io/jaureguy760/docker-var-aware-baseline:${TAG}"

docker buildx build \
  --platform linux/amd64 \
  -t "${IMAGE}" \
  --push \
  .

echo "Built and pushed ${IMAGE}"
