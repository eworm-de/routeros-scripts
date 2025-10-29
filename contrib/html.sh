#!/bin/sh

set -e

RELTO="$(dirname "${1}")"

sed \
	-e "s|__TITLE__|$(head -n1 "${1}")|" \
	-e "s|__STYLE__|$(realpath --relative-to="${RELTO}" general/style.css)|" \
	< "${0}.d/head.html"

markdown -f toc,idanchor "${1}" | sed \
	-e 's/href="\([-_\./[:alnum:]]*\)\.md"/href="\1.html"/g' \
	-e '/<h[1234] /s| id="\(.*\)">| id="\L\1">|'

printf '</body></html>'
