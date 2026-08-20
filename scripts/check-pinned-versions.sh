#!/usr/bin/env bash
# Compares the installer versions pinned in the docs (README.md,
# TOKEN_OPTIMIZATION_STACK.md, setup.sh) against the latest upstream tag/
# release. Exits 1 if any pin is behind, so CI can catch drift instead of
# docs silently going stale.

set -euo pipefail

FILES=(README.md TOKEN_OPTIMIZATION_STACK.md setup.sh)
STATUS=0

latest_tag() {
    # Highest vX.Y.Z git tag. Used for repos whose install.sh is pinned by
    # raw.githubusercontent.com/<repo>/<tag>/..., not by a GitHub Release.
    local repo="$1"
    curl -s "https://api.github.com/repos/$repo/tags" | python3 -c "
import json, re, sys
tags = [t['name'] for t in json.load(sys.stdin)]
semver = [t for t in tags if re.fullmatch(r'v\d+\.\d+\.\d+', t)]
key = lambda v: tuple(int(x) for x in v[1:].split('.'))
print(sorted(semver, key=key)[-1] if semver else '')
"
}

latest_release() {
    local repo="$1"
    curl -s "https://api.github.com/repos/$repo/releases/latest" | python3 -c "
import json, sys
print(json.load(sys.stdin).get('tag_name', ''))
"
}

check_pin() {
    local name="$1" pattern="$2" repo="$3" mode="$4"
    local pinned
    pinned=$(grep -ohE "$pattern" "${FILES[@]}" 2>/dev/null | head -1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || true)

    if [ -z "$pinned" ]; then
        echo "::warning::$name: no pinned version found in docs"
        return
    fi

    local latest
    if [ "$mode" = "tags" ]; then
        latest=$(latest_tag "$repo")
    else
        latest=$(latest_release "$repo")
    fi

    if [ -z "$latest" ]; then
        echo "::warning::$name: could not fetch latest version from $repo"
        return
    fi

    if [ "$pinned" != "$latest" ]; then
        echo "::warning::$name pinned to $pinned but $repo latest is $latest — docs are stale"
        STATUS=1
    else
        echo "$name: pinned $pinned matches latest $latest — OK"
    fi
}

check_pin "Caveman" 'caveman/v[0-9]+\.[0-9]+\.[0-9]+/install\.sh' "JuliusBrussee/caveman" "tags"
check_pin "LeanCTX" 'lean-ctx/v[0-9]+\.[0-9]+\.[0-9]+/install\.sh' "yvgude/lean-ctx" "releases"

exit $STATUS
