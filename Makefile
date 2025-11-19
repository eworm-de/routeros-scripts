# Makefile to generate data:
#  template scripts -> final scripts
#  markdown files -> html files

ALL_RSC		:= $(wildcard *.rsc */*.rsc)
GEN_RSC		:= $(wildcard *.capsman.rsc *.local.rsc *.wifi.rsc)

MARKDOWN	:= $(wildcard *.md doc/*.md doc/mod/*.md)
HTML		:= $(MARKDOWN:.md=.html)

DATE		?= $(shell date --rfc-email)
VERSION		?= $(shell git symbolic-ref --short HEAD 2>/dev/null)/$(shell git rev-list --count HEAD 2>/dev/null)/$(shell git rev-parse --short=8 HEAD 2>/dev/null)
export DATE VERSION

.PHONY: all checksums commitinfo docs rsc clean

all: checksums docs rsc

checksums: checksums.json

checksums.json: contrib/checksums.sh $(ALL_RSC)
	contrib/checksums.sh > $@

commitinfo: global-functions.rsc
	contrib/commitinfo.sh $< > $<~
	mv $<~ $<

docs: $(HTML)

%.html: %.md general/style.css contrib/html.sh contrib/html.sh.d/head.html contrib/html.sh.d/foot.html
	contrib/html.sh $< > $@

rsc: $(GEN_RSC)

%.capsman.rsc: %.template.rsc contrib/template-capsman.sh
	contrib/template-capsman.sh $< > $@

%.local.rsc: %.template.rsc contrib/template-local.sh
	contrib/template-local.sh $< > $@

%.wifi.rsc: %.template.rsc contrib/template-wifi.sh
	contrib/template-wifi.sh $< > $@

clean:
	rm -f $(HTML) checksums.json
	make -C contrib/ clean
