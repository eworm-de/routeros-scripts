#!/bin/sh

set -e

sed -i \
	-e '/href=/s|\.md|\.html|' \
	-e '/blockquote/s|/\* display \*/|display: none;|' \
	-e '/<!-- badges here \/\/-->/r badges.html' \
	-e '/<!-- badges here \/\/-->/d' \
	"${@}"
