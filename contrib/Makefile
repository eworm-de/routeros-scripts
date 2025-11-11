# Makefile

HTML	:= $(wildcard *.html)

.PHONY: all docs

all: docs

docs: $(HTML)
	sed -i '/href=/s|\.md|\.html|' $(HTML)
