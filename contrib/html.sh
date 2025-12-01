#!/bin/sh

set -e

RELTO="$(dirname "${1}")"

sed \
	-e "s|__TITLE__|$(head -n1 "${1}")|" \
	-e "s|__GENERAL__|$(realpath --relative-to="${RELTO}" general/)|" \
	-e "s|__ROOT__|$(realpath --relative-to="${RELTO}" ./)|" \
	< "${0}.d/head.html"

markdown -f toc,idanchor "${1}" | sed \
	-e 's/href="\([-_\./[:alnum:]]*\)\.md\(#[-[:alnum:]]*\)\?"/href="\1.html\2"/g' \
	-e '/<h[1234] /s| id="\(.*\)">| id="\L\1">|' \
	-e '/<h[1234] /s|-2[1789cd]-||g' -e '/<h[1234] /s|--26-amp-3b-||g' \
	-e '/^<pre>/s|pre|pre class="code" onclick="CopyToClipboard(this)"|g' \
	-e '/The above link may be broken on code hosting sites/s|blockquote|blockquote style="display: none;"|'

sed \
	-e "s|__DATE__|${DATE:-$(date --rfc-email)}|" \
	-e "s|__VERSION__|${VERSION:-unknown}|" \
	< "${0}.d/foot.html"
