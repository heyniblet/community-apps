#!/bin/bash
set -euo pipefail
version=$(cat PIXLET_VERSION)
test "$version" = v0.53.1 || { echo 'Update the reviewed Pixlet checksum with PIXLET_VERSION.' >&2; exit 1; }
archive="pixlet_${version}_linux-amd64.tar.gz"
curl --fail --location --silent --show-error "https://github.com/tronbyt/pixlet/releases/download/$version/$archive" -o "$RUNNER_TEMP/$archive"
printf '%s  %s\n' 8585ae29652bec004c31c1c5af2d9aa682ae86a87e037db6597a86e52fa2cfac "$RUNNER_TEMP/$archive" | sha256sum --check
sudo tar -C /usr/local/bin -xzf "$RUNNER_TEMP/$archive" pixlet
