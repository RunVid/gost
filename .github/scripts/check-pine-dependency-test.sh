#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fixture_dir="$(mktemp -d)"
trap 'rm -rf -- "$fixture_dir"' EXIT

cd "$fixture_dir"
export GOWORK=off GOPROXY=off GOTOOLCHAIN=local

for ref in refs/tags/v3.2.6-pine.4 refs/tags/v3.2.7-nightly.20261004 refs/heads/master; do
  export GITHUB_REF="$ref" GITHUB_REF_NAME="${ref##*/}"
  for dependency in \
    'github.com/RunVid/gost-x v0.8.1-pine.4' \
    'github.com/RunVid/gost-x v0.8.1-pine.3.0.20261004011625-5aa61c183912' \
    './local' \
    'github.com/example/gost-x v0.8.1-pine.4' \
    ''; do
    cat > go.mod <<'EOF'
module example.com/release-guard-test

go 1.24.0

require github.com/go-gost/x v0.8.1
EOF
    if [[ -n "$dependency" ]]; then
      printf '\nreplace github.com/go-gost/x => %s\n' "$dependency" >> go.mod
    fi
    if bash "$script_dir/check-pine-dependency.sh" > result.log 2>&1; then
      if [[ "$dependency" != 'github.com/RunVid/gost-x v0.8.1-pine.4' ]]; then
        echo "Accepted forbidden dependency for $ref: $dependency" >&2
        exit 1
      fi
    else
      if [[ "$dependency" == 'github.com/RunVid/gost-x v0.8.1-pine.4' ]]; then
        cat result.log >&2
        exit 1
      fi
      # Explicit replacements must reach the guard. With no replacement,
      # Go may itself fail closed resolving uncached upstream metadata offline.
      if [[ -n "$dependency" ]]; then
        grep -q 'Publishing requires a tagged RunVid/gost-x dependency' result.log
      fi
    fi
  done
done
echo 'Dependency gate passed for Pine tags, nightly tags, and Docker branch builds.'
