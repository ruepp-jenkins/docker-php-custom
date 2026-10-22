#!/bin/bash
set -e
echo "Starting build workflow"

scripts/docker_initialize.sh

# target platforms (comma separated), e.g. "linux/amd64,linux/arm64" to also build arm64
BUILD_PLATFORMS=${BUILD_PLATFORMS:-linux/amd64}
echo "Target platforms: ${BUILD_PLATFORMS}"

# reads a label from the already pushed image (first platform) - empty if the image does not exist
get_pushed_label() {
    docker buildx imagetools inspect "$1" \
        --format "{{range \$p, \$i := .Image}}{{index \$i.Config.Labels \"$2\"}}{{break}}{{end}}" 2>/dev/null || true
}

for file in Dockerfiles/*; do
    TAG=$(basename "$file")

    # skip versions switched off in php_versions.conf
    if grep -qE "^${TAG}=(off|false|0|no)[[:space:]]*$" php_versions.conf 2>/dev/null; then
        echo "Skipping tag ${TAG} (disabled in php_versions.conf)"
        continue
    fi

    DATESTAMP=$(date +%Y%m%d)

    # fingerprint of everything that influences the result: base image, build files and target platforms
    BASE_IMAGE=$(sed -n 's/^FROM[[:space:]]\+\([^[:space:]]\+\).*/\1/p' "${file}" | head -n 1)
    BASE_DIGEST=$(docker buildx imagetools inspect "${BASE_IMAGE}" --format '{{.Manifest.Digest}}')
    INPUTS_HASH=$( (cat "${file}"; find scripts/dockerfile -type f | sort | xargs cat; echo "${BUILD_PLATFORMS}") | sha256sum | cut -d' ' -f1)

    # on main/master only build if the base image or the build inputs changed (set FORCE_BUILD=true to override)
    if [ "$BRANCH_NAME" = "master" ] || [ "$BRANCH_NAME" = "main" ]
    then
        if [ "${FORCE_BUILD}" != "true" ] \
            && [ "$(get_pushed_label ${IMAGE_FULLNAME}:${TAG} base.digest)" = "${BASE_DIGEST}" ] \
            && [ "$(get_pushed_label ${IMAGE_FULLNAME}:${TAG} inputs.hash)" = "${INPUTS_HASH}" ]
        then
            echo "Skipping tag ${TAG} (base image ${BASE_IMAGE} and build inputs unchanged)"
            continue
        fi
    fi
    
    echo "Building tag ${TAG} from file: ${file}"

    # run build
    echo "[${BRANCH_NAME}] Building images: ${IMAGE_FULLNAME}"
    if [ "$BRANCH_NAME" = "master" ] || [ "$BRANCH_NAME" = "main" ]
    then
        docker buildx build \
            --platform ${BUILD_PLATFORMS} \
            -t ${IMAGE_FULLNAME}:${TAG} \
            -t ${IMAGE_FULLNAME}:${TAG}-${DATESTAMP} \
            --label base.digest=${BASE_DIGEST} \
            --label inputs.hash=${INPUTS_HASH} \
            -f "${file}" \
            --pull \
            --push .
    else
        docker buildx build \
            --platform ${BUILD_PLATFORMS} \
            -t ${IMAGE_FULLNAME}-test:${BRANCH_NAME}-${TAG} \
            --label base.digest=${BASE_DIGEST} \
            --label inputs.hash=${INPUTS_HASH} \
            -f "${file}" \
            --pull \
            --push .
    fi
done

# cleanup
scripts/docker_cleanup.sh
