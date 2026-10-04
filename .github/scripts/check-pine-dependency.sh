#!/usr/bin/env bash
set -euo pipefail

# Every publishing path from this Pine tree must use a reviewed dependency
# release, regardless of the executable tag's spelling (including nightlies).
dependency="$(go list -m -f '{{with .Replace}}{{.Path}} {{.Version}}{{end}}' github.com/go-gost/x)"
if [[ ! "$dependency" =~ ^github\.com/RunVid/gost-x\ v[0-9]+\.[0-9]+\.[0-9]+-pine\.[0-9]+$ ]]; then
  echo 'Publishing requires a tagged RunVid/gost-x dependency; review commit pins cannot ship.' >&2
  exit 1
fi
