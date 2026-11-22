#!/bin/bash
# Bump srcpkgs/grumpydove/template to the newest upstream tag, if newer.
# Prints "updated=<version>" or "updated=" for $GITHUB_OUTPUT.
#
# Upstream tags look like v1.0.0-beta11; the xbps version is 1.0.0beta11
# (xbps-src allows neither "-" nor "_" in a version).
# For comparing, both become 1.0.0~beta11, which sort -V puts before 1.0.0.
set -euo pipefail

TEMPLATE=srcpkgs/grumpydove/template
UPSTREAM=https://git.keinpfusch.net/loweel/grumpydove

latest_tag=$(git ls-remote --tags --refs "$UPSTREAM" 'v*' \
	| sed 's|.*refs/tags/||' \
	| sed 's/^v//; s/-/~/' | sort -V | tail -n1)
[ -n "$latest_tag" ] || { echo "no upstream tag found" >&2; exit 1; }

latest=${latest_tag//\~/}            # 1.0.0beta11, the xbps version
upstream_tag=v${latest_tag//\~/-}     # v1.0.0-beta11, the git tag
current=$(sed -n 's/^version=//p' "$TEMPLATE")

if [ "$latest" = "$current" ] \
	|| [ "$(printf '%s\n%s\n' "$(sed -E 's/([0-9])(alpha|beta|rc)/\1~\2/' <<<"$current")" "$latest_tag" | sort -V | tail -n1)" != "$latest_tag" ]; then
	echo "grumpydove $current is up to date (upstream: $latest)" >&2
	echo "updated="
	exit 0
fi

sum=$(curl -fsSL "$UPSTREAM/archive/$upstream_tag.tar.gz" | sha256sum | cut -d' ' -f1)
sed -i -e "s/^version=.*/version=${latest}/" \
	-e "s/^revision=.*/revision=1/" \
	-e "s/^checksum=.*/checksum=${sum}/" "$TEMPLATE"
echo "grumpydove: $current -> $latest" >&2
echo "updated=$latest"
