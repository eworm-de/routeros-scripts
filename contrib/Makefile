# Makefile

HTML	:= $(wildcard *.html)

.PHONY: all docs

all: docs

docs: $(HTML)
	sed -i \
		-e '/href=/s|\.md|\.html|' \
		-e '/blockquote/s|/\*! display \*/|display: none;|' \
		 $(HTML)
