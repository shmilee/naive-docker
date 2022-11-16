#!/bin/bash

HEADSCALE_VERSION=${1:-0.17.0-beta4}
HEADSCALE_BIN_URL=${HEADSCALE_BIN_URL:-'https://github.com/juanfont/headscale/releases/download/v%s/headscale_%s_linux_amd64'}
HEADSCALE_CACHE_BIN=/srv/headscale_${HEADSCALE_VERSION}_linux_amd64

if [ ! -f "${HEADSCALE_CACHE_BIN}" ]; then
    wget -P /srv -O ${HEADSCALE_CACHE_BIN} `printf "${HEADSCALE_BIN_URL}" ${HEADSCALE_VERSION} ${HEADSCALE_VERSION}`
fi

if [ -f ${HEADSCALE_CACHE_BIN} ]; then
    echo "==> Using headscale: $HEADSCALE_VERSION ..."
    install -Dm755 -v ${HEADSCALE_CACHE_BIN} /usr/bin/headscale
fi
