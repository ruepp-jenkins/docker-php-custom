#!/bin/bash
set -e
echo "Starting build workflow"

scripts/docker_initialize.sh

for file in Dockerfiles/*; do
    TAG=$(basename "$file")
    
    # run build
    echo "[${BRANCH_NAME}] Building images: ${IMAGE_FULLNAME}"
    if [ "$BRANCH_NAME" = "master" ] || [ "$BRANCH_NAME" = "main" ]
    then
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t ${IMAGE_FULLNAME}:${TAG} \
            --push .
    else
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t ${IMAGE_FULLNAME}-test:${BRANCH_NAME}-${TAG} \
            --push .
    fi
done



# cleanup
scripts/docker_cleanup.sh
