#!/usr/bin/env bash
# Run with the normal Niblet HTTPS egress proxy configured in the environment.
set -euo pipefail
cd "$(dirname "$0")/.."
pixlet="${PIXLET:-../niblet-cli/niblet}"
output="$(mktemp -d)"
trap 'rm -rf "$output"' EXIT
for source in apps/mhkyscores/mhky_scores.star apps/nflscores/nfl_scores.star apps/wikifeatimage/wiki_feat_image.star; do
  "$pixlet" lint "$source"
  for scale in 1 2; do
    flags=()
    if [[ "$scale" = 2 ]]; then flags+=(--2x); fi
    "$pixlet" render "$source" --timeout 20s --max-duration 15s --silent \
      --output "$output/image.webp" --metadata-output "$output/metadata.json" "${flags[@]}"
    test -s "$output/image.webp"
    python3 - "$output/metadata.json" <<'PY'
import json, sys
requests = json.load(open(sys.argv[1])).get('http_requests', [])
assert requests and all(r.get('status_code') == 200 and not r.get('error_kind') for r in requests)
assert len(requests) <= 7, 'cold render exceeded its bounded request budget'
PY
  done
done
