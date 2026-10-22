# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Language

The project language is English: write code, comments, commit messages, and documentation in English.

## What this is

A personal Docker image (`ruepp/php-custom` on Docker Hub) built on the official `php:<version>-apache` images with extra PHP extensions and Apache modules pre-installed. There is no application code, test suite or linter — the repo is Dockerfiles plus shell scripts, built and pushed by Jenkins.

## Build

CI (`Jenkinsfile`) runs `scripts/start.sh`, which logs in to Docker Hub (`DOCKER_USERNAME`/`DOCKER_API_PASSWORD`), creates a buildx builder, then builds every file in `Dockerfiles/` for the platforms in `BUILD_PLATFORMS` (set in the Jenkinsfile `environment`, default `linux/amd64`; use `linux/amd64,linux/arm64` to re-enable arm64) and pushes. Per tag the flow is: build for `linux/amd64` with `--load` → `scripts/test_image.sh` → only if the tests pass, build for `BUILD_PLATFORMS` and `--push` (second build reuses the cache). A failing tag is not pushed, the other tags continue, and the run exits 1 at the end. Tests only run on amd64. It expects `IMAGE_FULLNAME` and `BRANCH_NAME` in the environment. Jenkins is also triggered whenever an upstream `php:<tag>` base image changes on Docker Hub (one URLTrigger entry per PHP version, polled every 30 min).

- `main`/`master` branch: pushes `ruepp/php-custom:<tag>` and `<tag>-<YYYYMMDD>`. A tag is only rebuilt if its base image digest or its build inputs (Dockerfile, `scripts/dockerfile/`, `BUILD_PLATFORMS`) changed: both are stored as image labels (`base.digest`, `inputs.hash`) and compared against the pushed image. Set `FORCE_BUILD=true` to rebuild everything.
- Any other branch: pushes `ruepp/php-custom-test:<branch>-<tag>` only.

To build locally for a single platform (no push), from the repo root:

```bash
docker build --build-arg TARGETPLATFORM=linux/amd64 -f Dockerfiles/8.2-apache -t php-custom:test .
```

`TARGETPLATFORM` must be set (buildx sets it automatically; plain `docker build` needs the build-arg) because `build.sh` sources `platforms/${TARGETPLATFORM}.sh`.

## Architecture

- **`php_versions.conf`**: on/off switch per `Dockerfiles/<tag>` (`8.5-apache=off`); `start.sh` skips disabled tags, and unlisted ones are built. The Jenkinsfile URLTrigger cannot read this file, so when switching a version on/off also add/remove its `URLTriggerEntry` there.
- **`Dockerfiles/<tag>`**: the filename *is* the image tag (e.g. `8.2-apache` → `ruepp/php-custom:8.2-apache`). Each file is a thin `FROM php:<tag>`, copies `scripts/dockerfile/` to `/build`, and runs `build.sh`. To add a PHP version/variant, add a new file here named after the tag; `start.sh` picks it up automatically (also add it to `php_versions.conf` and the Jenkinsfile URLTrigger entries).
- **`scripts/dockerfile/build.sh`**: orchestrates the in-image install steps in order: `apt-get.sh` (dev libraries) → `platforms/${TARGETPLATFORM}.sh` (per-arch hooks, currently no-ops) → `php_extensions_default.sh` (`docker-php-ext-install`) → `php_extensions_pecl.sh` (pecl) → `apache_mods.sh` → `php_cleanup.sh` → `cleanup.sh` (removes apt lists, `/tmp`, and `/build`).
- **`scripts/*.sh`** (outside `dockerfile/`): host/CI-side scripts run by Jenkins (docker login, buildx setup, prune), not part of the image.

**`scripts/dockerfile/extensions.conf`** is the single source of truth for everything installed on top of the base image: `ext` (docker-php-ext-install, with optional configure args), `pecl`, `apache` (a2enmod) and optional `smoke` PHP one-liners. The install scripts read it, and so does `scripts/test_image.sh`, which starts the built image and checks that every listed extension and apache module is loaded and listed in phpinfo, that nothing the base image ships got lost, that `php -m`/`php -i`/phpinfo/logs show no warnings or errors, and that all `smoke` expressions are true. To add an extension: install the needed `-dev` library in `apt-get.sh` and add one line to `extensions.conf` (no test changes needed). Extensions the base image already ships (e.g. opcache in PHP 8.5) are skipped automatically.
