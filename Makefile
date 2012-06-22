#
#	xt_dns Makefile
#	Copyright (c) Bartlomiej Korupczynski, 2011
#
#	This is kernel module used to match DNS MX queries
# 
#	This file is distributed under the terms of the GNU General Public
#	License (GPL). Copies of the GPL can be obtained from gnu.org/gpl.
#

NAME = xt_dns
VERSION = 0.1.0
DISTFILES = *.[ch] Makefile ChangeLog

KVERSION = $(shell uname -r)
KDIR = /lib/modules/$(KVERSION)/build
MDIR = /lib/modules/$(KVERSION)/local/
XDIR = /lib/xtables/
IPTABLES = iptables
IP6TABLES = ip6tables

obj-m = $(NAME).o

build: config.h module userspace
install: module-install userspace-install
module: $(NAME).ko
userspace: lib$(NAME).so


config.h: Makefile
	@echo "making config.h"
	@echo "/* generated by Makefile */" >config.h
	@echo "#define VERSION \"$(VERSION)\"" >>config.h

xt_dns.ko: xt_dns.c xt_dns.h config.h
	$(MAKE) -C $(KDIR) M=$(PWD) modules

# in case of problems add path to iptables sources like:
# -I/usr/src/sources/iptables-1.4.2/include/
libxt_dns.so: libxt_dns.c xt_dns.h config.h
	$(CC) -fPIC -Wall -shared -o libxt_dns.so libxt_dns.c

module-install: xt_dns.ko
	sync
	mkdir -p $(MDIR) || :
	install *.ko $(MDIR)
	depmod -a
	sync

userspace-install: libxt_dns.so
	install *.so $(XDIR)

clean:
	rm -f libxt_dns.so config.h
	$(MAKE) -C $(KDIR) M=$(PWD) clean

dist:
	rm -f $(NAME)-$(VERSION).tar.gz
	mkdir -p tmp/$(NAME)-$(VERSION)
	cp -a $(DISTFILES) tmp/$(NAME)-$(VERSION)
	cd tmp && tar zcf ../$(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION)/
	rm -rf tmp/$(NAME)-$(VERSION)
	rmdir --ignore-fail-on-non-empty tmp
	@echo OK: dist

distcheck: dist
	mkdir -p tmp
	rm -rf tmp/$(NAME)-$(VERSION)
	cd tmp && tar zxf ../$(NAME)-$(VERSION).tar.gz
	cd tmp/$(NAME)-$(VERSION) && $(MAKE) build
	rm -rf tmp/$(NAME)-$(VERSION)
	rmdir --ignore-fail-on-non-empty tmp
	@echo OK: distcheck

upload:
	./.mkupload.sh

#
# usage examples
#

x-ipt-add:
	sync
	$(IPTABLES) -F dnsmx-test 2>/dev/null || $(IPTABLES) -N dnsmx-test
	$(IPTABLES) -A dnsmx-test -p udp --dport 53
	$(IPTABLES) -A dnsmx-test -p udp --dport 53 -m dns --dns-query A
	$(IPTABLES) -A dnsmx-test -p udp --dport 53 -m dns --dns-query AAAA
	$(IPTABLES) -A dnsmx-test -p udp --dport 53 -m dns --dns-query MX -j LOG --log-prefix 'dns:' --log-ip-options --log-tcp-options
	$(IPTABLES) -A dnsmx-test -p udp --dport 53 -m dns --dns-query MX -j REJECT --reject-with admin-prohib
	$(IPTABLES) -D OUTPUT -j dnsmx-test 2>/dev/null || :
	$(IPTABLES) -I OUTPUT -j dnsmx-test

x-ipt-clean:
	$(IPTABLES) -D OUTPUT -j dnsmx-test || :
	$(IPTABLES) -F dnsmx-test || :
	$(IPTABLES) -X dnsmx-test || :
	sync
	rmmod xt_dns || :

x-ip6t-add:
	sync
	$(IP6TABLES) -F dnsmx-test 2>/dev/null || $(IP6TABLES) -N dnsmx-test
	$(IP6TABLES) -A dnsmx-test -p udp --dport 53
	$(IP6TABLES) -A dnsmx-test -p udp --dport 53 -m dns --dns-query A
	$(IP6TABLES) -A dnsmx-test -p udp --dport 53 -m dns --dns-query AAAA
	$(IP6TABLES) -A dnsmx-test -p udp --dport 53 -m dns --dns-query MX -j LOG --log-prefix 'dns:' --log-ip-options --log-tcp-options
	$(IP6TABLES) -A dnsmx-test -p udp --dport 53 -m dns --dns-query MX -j REJECT --reject-with adm-prohib
	$(IP6TABLES) -D OUTPUT -j dnsmx-test 2>/dev/null || :
	$(IP6TABLES) -I OUTPUT -j dnsmx-test

x-ip6t-clean:
	$(IP6TABLES) -D OUTPUT -j dnsmx-test || :
	$(IP6TABLES) -F dnsmx-test || :
	$(IP6TABLES) -X dnsmx-test || :
	sync
	rmmod xt_dns || :

