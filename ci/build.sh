#!/bin/bash
# Build the packages for every architecture and assemble a signed xbps
# repository in /work/public/current.
#
# Runs as root inside a privileged ghcr.io/void-linux/void-glibc-full
# container with this repository mounted on /work. GNAT cannot be
# cross-compiled by xbps-src, so only native x86_64 builds are done;
# x86_64-musl can be tried with ARCHS="x86_64 x86_64-musl".
#
# Environment:
#   ARCHS          space-separated target architectures
#   XBPS_PRIVKEY   PEM private key used to sign repodata and packages
#                  (optional: without it the repository is left unsigned)
#   SIGNED_BY      signer name stored in the repodata
set -euo pipefail

ARCHS=${ARCHS:-"x86_64"}
SIGNED_BY=${SIGNED_BY:-"void-grumpydove <https://github.com/akamizi/void-grumpydove>"}
PKGS="gprbuild grumpydove"
OUT=/work/public/current

msg() { printf '\033[32m==> %s\033[0m\n' "$*"; }

msg "Preparing container"
mkdir -p /etc/xbps.d && cp /usr/share/xbps.d/*-repository-*.conf /etc/xbps.d/
xbps-install -y sudo git
useradd -G xbuilder -M builder

msg "Cloning void-packages"
git clone --depth 1 https://github.com/void-linux/void-packages.git /build
cp -r /work/srcpkgs/. /build/srcpkgs/
chown -R builder:builder /build
cd /build

cat >> etc/conf <<'EOF'
XBPS_CHROOT_CMD=uchroot
XBPS_ALLOW_RESTRICTED=yes
EOF

# xbps-src cannot cross-build between libcs of the same machine, so musl
# targets get their own x86_64-musl masterdir.
host_for() {
	case "$1" in
	*-musl) echo x86_64-musl ;;
	*) echo x86_64 ;;
	esac
}

for host in $(for a in $ARCHS; do host_for "$a"; done | sort -u); do
	msg "Bootstrapping $host masterdir"
	sudo -Eu builder ./xbps-src -A "$host" binary-bootstrap
done

for arch in $ARCHS; do
	host=$(host_for "$arch")
	msg "Building for $arch (host $host)"
	if [ "$arch" = "$host" ]; then
		sudo -Eu builder ./xbps-src -A "$host" pkg grumpydove
	else
		sudo -Eu builder ./xbps-src -A "$host" -a "$arch" pkg grumpydove
	fi
done

msg "Assembling repository"
rm -rf "$OUT" && mkdir -p "$OUT"
for pkg in $PKGS; do
	cp hostdir/binpkgs/"$pkg"-[0-9]*.xbps "$OUT"/
done
cd "$OUT"
for arch in $ARCHS; do
	XBPS_TARGET_ARCH=$arch xbps-rindex -a "$OUT"/*."$arch".xbps
done

if [ -n "${XBPS_PRIVKEY:-}" ]; then
	msg "Signing repository"
	key=$(mktemp)
	printf '%s\n' "$XBPS_PRIVKEY" > "$key"
	for arch in $ARCHS; do
		XBPS_TARGET_ARCH=$arch xbps-rindex --signedby "$SIGNED_BY" --privkey "$key" -s "$OUT"
	done
	xbps-rindex --privkey "$key" -S "$OUT"/*.xbps
	rm -f "$key"
else
	msg "XBPS_PRIVKEY not set: repository left unsigned"
fi

chown -R "$(stat -c %u:%g /work)" /work/public
ls -l "$OUT"
