#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

set -e

echo "uploading binpkgs ..."
PKGDIR="$(portageq envvar PKGDIR)"
