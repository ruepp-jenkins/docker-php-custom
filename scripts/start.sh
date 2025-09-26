#!/bin/bash
set -e
echo "Starting build workflow"

scripts/docker_initialize.sh

for file in Dockerfiles/*; do
    TAG=$(basename "$file")
    DATESTAMP=$(date +%Y%m%d)
    
    echo "Building tag ${TAG} from file: ${file}"

    # run build
    echo "[${BRANCH_NAME}] Building images: ${IMAGE_FULLNAME}"
    if [ "$BRANCH_NAME" = "master" ] || [ "$BRANCH_NAME" = "main" ]
    then
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t ${IMAGE_FULLNAME}:${TAG} \
            -t ${IMAGE_FULLNAME}:${TAG}-${DATESTAMP} \
            -f "${file}" \
            --pull \
            --push .
    else
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            -t ${IMAGE_FULLNAME}-test:${BRANCH_NAME}-${TAG} \
            -f "${file}" \
            --pull \
            --push .
    fi
done

# cleanup
scripts/docker_cleanup.sh
