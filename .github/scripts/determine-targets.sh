#!/bin/bash
set -euo pipefail
old_commit=$(git merge-base "$BASE_SHA" "$HEAD_SHA")
targets=$(git diff --name-only "$old_commit" "$HEAD_SHA" -- apps/ | awk -F/ 'NF >= 3 {print $1 "/" $2}' | sort -u | paste -sd ' ' -)
printf 'targets=%s\n' "$targets" >> "$GITHUB_OUTPUT"
