# void-grumpydove

Unofficial [Void Linux](https://voidlinux.org) binary repository for
[GrumpyDove](https://git.keinpfusch.net/loweel/grumpydove), a mail client in
the manner of Eudora Pro, written in Ada and Qt.

Packages are built by GitHub Actions and published, signed, on GitHub Pages.
A daily job looks at the tags of the upstream repository; when a new one
appears it bumps the template, rebuilds and republishes the repository.

Architecture: `x86_64` (glibc).

## Install

```sh
echo 'repository=https://akamizi.github.io/void-grumpydove/current' \
  | sudo tee /etc/xbps.d/20-grumpydove.conf
sudo xbps-install -S grumpydove
```

On the first sync xbps shows the key fingerprint and asks you to import it.
It must match the one published below.

Signing key fingerprint:

```
(to be filled in after the first signed build)
```

## Contents

| Package | Notes |
|---|---|
| `grumpydove` | the mail client |
| `gprbuild` | AdaCore's build tool, needed to build GrumpyDove, not packaged in Void |

Everything else comes from the official Void repositories.

Upstream versions such as `1.0.0-beta11` become `1.0.0beta11` in xbps,
which sorts before `1.0.0` and after `1.0.0beta10`.

## Maintenance

- `srcpkgs/` holds standard `xbps-src` templates, overlaid on a fresh
  shallow clone of `void-linux/void-packages` at build time.
- `ci/check-update.sh` bumps `grumpydove` to the newest upstream tag.
- `ci/build.sh` builds inside a `void-glibc-full` container, then indexes
  and signs the repository with the `XBPS_PRIVKEY` secret.
- Run the workflow by hand from the Actions tab, or push a template change.
- The GNAT Ada compiler cannot be cross-compiled by `xbps-src`, so only the
  native x86_64 build is made. `ARCHS="x86_64 x86_64-musl"` is worth a try
  for musl.

### One-time setup

```sh
openssl genrsa -out privkey.pem 4096          # keep it out of the repo
```

1. Settings > Secrets and variables > Actions: add `XBPS_PRIVKEY` with the
   content of `privkey.pem`.
2. Settings > Pages: Source = GitHub Actions.
3. Run the workflow once by hand; take the fingerprint from the first
   install (or `xbps-rindex`) and put it above.

To build locally:

```sh
docker run --rm --privileged -v "$PWD:/work" -e ARCHS=x86_64 \
  ghcr.io/void-linux/void-glibc-full sh /work/ci/entry.sh
# repository in ./public/current
```

## Licences

The templates are offered under the licence of void-packages (BSD-2-Clause).
GrumpyDove is EUPL-1.2; gprbuild is GPL-3.0-or-later with the GCC runtime
exception.
