#!/bin/sh

set -e

sed "s|__TITLE__|$(head -n1 "${1}")|" < "${0}.d/head.html"

markdown -f toc,idanchor "${1}" | sed \
	-e 's/href="\([-_\./[:alnum:]]*\)\.md"/href="\1.html"/g' \
	-e '/<h[1234] /s| id="\(.*\)">| id="\L\1">|'

printf '</body></html>'
