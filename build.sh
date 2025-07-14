#!/usr/bin/env bash

## Global settings
DOCKER_IMAGE="${DOCKER_REPO:-smtp-relay}"
DOCKERFILE_PATH="Dockerfile"

set -euo pipefail

## ─── Konfiguration ───────────────────────────────────────────────────────────
# Alpine-Version, kann per ENV überschrieben werden
ALPINE_VERSION="${ALPINE_VERSION:-3.18}"
# Architektur
ARCH="$(uname -m)"
## ─────────────────────────────────────────────────────────────────────────────

echo "→ Alpine:   ${ALPINE_VERSION}"
echo "→ Arch:     ${ARCH}"

# Helper: API-Endpoint bauen
api_url() {
  local pkg="$1"
  echo "https://pkgs.alpinelinux.org/api/packages?name=${pkg}&repo=main&arch=${ARCH}&branch=v${ALPINE_VERSION}"
}

# 1) Postfix-Version per JSON-API ziehen
if [[ -z "${POSTFIX_VERSION:-}" ]]; then
  echo "→ Fetching latest postfix from $(api_url postfix)…"
  POSTFIX_VERSION="$(curl -s "$(api_url postfix)" \
    | grep -Po '"version":"\K[0-9A-Za-z.\-]+' \
    | head -n1)"
  test -n "$POSTFIX_VERSION"
fi
echo "→ Postfix:  ${POSTFIX_VERSION}"

# 2) Rsyslog-Version per JSON-API ziehen
if [[ -z "${RSYSLOG_VERSION:-}" ]]; then
  echo "→ Fetching latest rsyslog from $(api_url rsyslog)…"
  RSYSLOG_VERSION="$(curl -s "$(api_url rsyslog)" \
    | grep -Po '"version":"\K[0-9A-Za-z.\-]+' \
    | head -n1)"
  test -n "$RSYSLOG_VERSION"
fi
echo "→ Rsyslog:  ${RSYSLOG_VERSION}"

# 3) VCS-Reference (Commit-Hash)
if [[ -n "${SOURCE_COMMIT:-}" ]]; then
  VCS_REF="${SOURCE_COMMIT}"
elif [[ -n "${TRAVIS_COMMIT:-}" ]]; then
  VCS_REF="${TRAVIS_COMMIT}"
else
  VCS_REF="$(git rev-parse --short HEAD)"
fi
echo "→ VCS-Ref:  ${VCS_REF}"

# 4) Image-Version aus VERSION-Datei
IMAGE_VERSION="$(< VERSION)"
echo "→ Image-Ver:${IMAGE_VERSION}"

# 5) Build-Tag
BUILD_TAG="${DOCKER_IMAGE}:building"
echo "→ Build-Tag:${BUILD_TAG}"

## ─── Build ───────────────────────────────────────────────────────────────────
docker build \
  --build-arg "ALPINE_VERSION=${ALPINE_VERSION}" \
  --build-arg "POSTFIX_VERSION=${POSTFIX_VERSION}" \
  --build-arg "RSYSLOG_VERSION=${RSYSLOG_VERSION}" \
  --label "org.label-schema.build-date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --label "org.label-schema.name=smtp-relay" \
  --label "org.label-schema.description=SMTP server configured as a email relay" \
  --label "org.label-schema.url=https://github.com/Turgon37/docker-smtp-relay" \
  --label "org.label-schema.vcs-ref=${VCS_REF}" \
  --label "org.label-schema.vcs-url=https://github.com/Turgon37/docker-smtp-relay" \
  --label "org.label-schema.vendor=Pierre GINDRAUD" \
  --label "org.label-schema.version=${IMAGE_VERSION}" \
  --label "org.label-schema.schema-version=1.0" \
  --label "application.postfix.version=${POSTFIX_VERSION}" \
  --label "application.rsyslog.version=${RSYSLOG_VERSION}" \
  --tag "${BUILD_TAG}" \
  --file "${DOCKERFILE_PATH}" \
  .
