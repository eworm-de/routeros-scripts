# Makefile

HTML	:= $(wildcard *.html)

.PHONY: all docs

all: docs

docs: static-html.sh $(HTML)
	./static-html.sh $(HTML)
