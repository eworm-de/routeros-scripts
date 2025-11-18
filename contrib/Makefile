# Makefile

HTML	:= $(shell grep -xl '<!-- static html //-->' *.html)

.PHONY: all docs

all: docs

badges.html: badges.md
	markdown $< > $@

docs: static-html.sh $(HTML) badges.html
	./static-html.sh $(HTML)
