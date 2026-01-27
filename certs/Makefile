# Makefile to check certificates

CURL = curl \
	--capath /dev/null \
	--connect-timeout 5 \
	--output /dev/null \
	--silent

DOMAINS_DUAL = \
	api.macvendors.com/GTS-Root-R4 \
	api.telegram.org/Go-Daddy-Root-Certificate-Authority-G2 \
	cloudflare-dns.com/SSL-com-Root-Certification-Authority-ECC \
	dns.google/GTS-Root-RX \
	dns.quad9.net/DigiCert-Global-Root-G3 \
	git.eworm.de/Root-YE \
	gitlab.com/USERTrust-RSA-Certification-Authority \
	lists.blocklist.de/GTS-Root-R4 \
	matrix.org/GTS-Root-R4 \
	raw.githubusercontent.com/USERTrust-RSA-Certification-Authority \
	rsc.eworm.de/Root-YE \
	upgrade.mikrotik.com/ISRG-Root-X1
DOMAINS_IPV4 = \
	1.1.1.1/SSL-com-Root-Certification-Authority-ECC \
	8.8.8.8/GTS-Root-RX \
	9.9.9.9/DigiCert-Global-Root-G3 \
	api.mullvad.net/ISRG-Root-X1 \
	ipv4.showipv6.de/ISRG-Root-X1 \
	ipv4.tunnelbroker.net/Starfield-Root-Certificate-Authority-G2 \
	mkcert.org/ISRG-Root-X1 \
	ntfy.sh/ISRG-Root-X1 \
	www.dshield.org/GTS-Root-R4 \
	www.spamhaus.org/GTS-Root-R4
DOMAINS_IPV6 = \
	[2606\:4700\:4700\:\:1111]/SSL-com-Root-Certification-Authority-ECC \
	[2001\:4860\:4860\:\:8888]/GTS-Root-RX \
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
