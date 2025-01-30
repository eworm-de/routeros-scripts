# Makefile to check certificates

DOMAINS = \
	1.1.1.1/DigiCert-Global-Root-G2 \
	8.8.8.8/GTS-Root-R1 \
	9.9.9.9/DigiCert-Global-Root-G3 \
	api.macvendors.com/GTS-Root-R4 \
	api.mullvad.net/ISRG-Root-X1 \
	api.telegram.org/Go-Daddy-Root-Certificate-Authority-G2 \
	cloudflare-dns.com/DigiCert-Global-Root-G2 \
	dns.google/GTS-Root-R1 \
	dns.quad9.net/DigiCert-Global-Root-G3 \
	feodotracker.abuse.ch/GlobalSign \
	git.eworm.de/ISRG-Root-X2 \
	ipv4.showipv6.de/ISRG-Root-X1 \
	ipv4.tunnelbroker.net/Starfield-Root-Certificate-Authority-G2 \
	ipv6.showipv6.de/ISRG-Root-X1 \
	lists.blocklist.de/Certum-Trusted-Network-CA \
	matrix.org/GTS-Root-R4 \
	mkcert.org/ISRG-Root-X1 \
	ntfy.sh/ISRG-Root-X1 \
	sslbl.abuse.ch/GlobalSign \
	upgrade.mikrotik.com/ISRG-Root-X1 \
	www.dshield.org/ISRG-Root-X1 \
	www.spamhaus.org/GTS-Root-R4

.PHONY: $(DOMAINS)

all: $(DOMAINS)

$(DOMAINS):
	curl --output /dev/null --silent --connect-timeout 5 --capath /dev/null --cacert $(notdir $@).pem https://$(dir $@)
