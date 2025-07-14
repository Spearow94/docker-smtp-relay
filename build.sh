#!/usr/bin/env bash

## Global settings
DOCKER_IMAGE="${DOCKER_REPO:-smtp-relay}"
DOCKERFILE_PATH="Dockerfile"

set -e

## ─── Konfiguration (hier Versionen anpassen!) ───────────────────────────────
# Basis-Alpine-Version
ALPINE_VERSION="${ALPINE_VERSION:-3.18}"

# Postfix-Paketversion (z.B. 3.8.0-r0)
POSTFIX_VERSION="${POSTFIX_VERSION:-3.8.0-r0}"

# Rsyslog-Paketversion (z.B. 8.41.0-r0)
RSYSLOG_VERSION="${RSYSLOG_VERSION:-8.41.0-r0}"
## ──────────────────────────────────────────────────────────────────────────

# Architektur ermitteln
ARCH="$(uname --machine)"

echo "-> Alpine-Version:      ${ALPINE_VERSION}"
echo "-> Postfix-Version:     ${POSTFIX_VERSION}"
echo "-> Rsyslog-Version:     ${RSYSLOG_VERSION}"
echo "-> Ziel-Architektur:    ${ARCH}"

# VCS-Reference (Commit-Hash) ermitteln
if [[ -n "${SOURCE_COMMIT}" ]]; then
  VCS_REF="${SOURCE_COMMIT}"
elif [[ -n "${TRAVIS_COMMIT}" ]]; then
  VCS_REF="${TRAVIS_COMMIT}"
else
  VCS_REF="$(git rev-parse --short HEAD)"
fi
echo "-> VCS-Reference:       ${VCS_REF}"

# Image-Version (statisch in VERSION-Datei)
IMAGE_VERSION="$(cat VERSION)"
echo "-> Image-Version:       ${IMAGE_VERSION}"

# Name während des Builds
IMAGE_BUILD_NAME="${DOCKER_IMAGE}:building"
echo "-> Build-Tag:           ${IMAGE_BUILD_NAME}"

## ─── Build ────────────────────────────────────────────────────────────────
echo "=> Baue Image ${IMAGE_BUILD_NAME}"
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
  --tag "${IMAGE_BUILD_NAME}" \
  --file "${DOCKERFILE_PATH}" \
  .
