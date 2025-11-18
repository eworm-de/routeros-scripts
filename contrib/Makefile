# Makefile

HTML	:= $(shell grep -xl '<!-- static html //-->' *.html)

.PHONY: all docs clean

all: docs

badges.html: badges.md
	markdown $< > $@

docs: static-html.sh $(HTML) badges.html
	./static-html.sh $(HTML)

clean:
	rm -f badges.html
	git checkout HEAD -- $(HTML)
