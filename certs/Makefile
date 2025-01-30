# Makefile to check certificates

CURL = curl \
	--capath /dev/null \
	--connect-timeout 5 \
	--output /dev/null \
	--silent

DOMAINS_DUAL = \
	api.macvendors.com/GTS-Root-R4 \
	api.telegram.org/Go-Daddy-Root-Certificate-Authority-G2 \
	cloudflare-dns.com/DigiCert-Global-Root-G2 \
	dns.google/GTS-Root-R1 \
	dns.quad9.net/DigiCert-Global-Root-G3 \
	git.eworm.de/ISRG-Root-X2 \
	lists.blocklist.de/Certum-Trusted-Network-CA \
	matrix.org/GTS-Root-R4 \
	raw.githubusercontent.com/DigiCert-Global-Root-G2 \
	rsc.eworm.de/ISRG-Root-X2 \
	upgrade.mikrotik.com/ISRG-Root-X1
DOMAINS_IPV4 = \
	1.1.1.1/DigiCert-Global-Root-G2 \
	8.8.8.8/GTS-Root-R1 \
	9.9.9.9/DigiCert-Global-Root-G3 \
	api.mullvad.net/ISRG-Root-X1 \
	feodotracker.abuse.ch/GlobalSign \
	ipv4.showipv6.de/ISRG-Root-X1 \
	ipv4.tunnelbroker.net/Starfield-Root-Certificate-Authority-G2 \
	mkcert.org/ISRG-Root-X1 \
	ntfy.sh/ISRG-Root-X1 \
	sslbl.abuse.ch/GlobalSign \
	www.dshield.org/ISRG-Root-X1 \
	www.spamhaus.org/GTS-Root-R4
DOMAINS_IPV6 = \
	[2606\:4700\:4700\:\:1111]/DigiCert-Global-Root-G2 \
	[2001\:4860\:4860\:\:8888]/GTS-Root-R1 \
	[2620\:fe\:\:9]/DigiCert-Global-Root-G3 \
	ipv6.showipv6.de/ISRG-Root-X1

.PHONY: $(DOMAINS_DUAL) $(DOMAINS_IPV4) $(DOMAINS_IPV6)

all: $(DOMAINS_DUAL) $(DOMAINS_IPV4) $(DOMAINS_IPV6)

$(DOMAINS_DUAL):
ifndef NOIPV4
	$(CURL) -4 --cacert $(notdir $@).pem https://$(dir $@)
endif
ifndef NOIPV6
	$(CURL) -6 --cacert $(notdir $@).pem https://$(dir $@)
endif

$(DOMAINS_IPV4):
ifndef NOIPV4
	$(CURL) -4 --cacert $(notdir $@).pem https://$(dir $@)
endif

$(DOMAINS_IPV6):
ifndef NOIPV6
	$(CURL) -6 --cacert $(notdir $@).pem https://$(dir $@)
endif
