#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version=${1:-}

if [ -z "$version" ]; then
    version=$(git -C "$project_root" describe \
        --tags \
        --exact-match \
        --match '[0-9]*.[0-9]*.[0-9]*' \
        2>/dev/null || true)
fi

if ! printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    version=$(git -C "$project_root" rev-parse --short=12 HEAD)
fi

dist_dir="$project_root/dist"
archive="$dist_dir/Source-Water-$version.zip"

mkdir -p "$dist_dir"
rm -f "$archive"

(
    cd "$project_root"
    zip \
        -q \
        -r \
        -X \
        "$archive" \
        shaders \
        COPYRIGHT \
        LICENSE \
        THIRD_PARTY_NOTICES.md \
        README.md \
        -x '*.DS_Store'
)

echo "$archive"
