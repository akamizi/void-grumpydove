#!/bin/sh
# Container entrypoint: the void images ship without bash.
set -e
xbps-install -Syu xbps
xbps-install -yu
xbps-install -y bash
exec bash /work/ci/build.sh
