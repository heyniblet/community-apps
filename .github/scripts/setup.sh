#!/bin/bash
set -euo pipefail
# Niblet's reviewed runtime adds frame_keys; upstream Pixlet cannot evaluate it.
version=$(cat PIXLET_VERSION)
test "$version" = v0.54.12 || { echo 'Update the reviewed runtime checksum with PIXLET_VERSION.' >&2; exit 1; }
archive="niblet_${version}_linux_amd64.tar.gz"
curl --fail --location --silent --show-error "https://cdn.heyniblet.com/web-assets/releases/niblet-cli/$version/$archive" -o "$RUNNER_TEMP/$archive"
printf '%s  %s\n' ed142e5c029748ce7e2e3914e9ce8c39700d3581c95ef352ddc814331ae33fe8 "$RUNNER_TEMP/$archive" | sha256sum --check
sudo tar -C /usr/local/bin -xzf "$RUNNER_TEMP/$archive" niblet pixlet
