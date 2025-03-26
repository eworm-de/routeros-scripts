#!/bin/sh

# generate a checksums file as used by $ScriptInstallUpdate

set -e

md5sum $(find -name '*.rsc' | sort) | \
	sed -e "s| \./||" -e 's|.rsc$||' | \
	jq --raw-input --null-input '[ inputs | split (" ") | { (.[1]): (.[0]) }] | add' > 'checksums.json'
