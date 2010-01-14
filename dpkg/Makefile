BUILDER := debian-package-builder
BUILDCMD := $(BUILDER)/bin/dpbuilder
ARCH := $(shell uname -m)
DIST := $(shell lsb_release -a 2>/dev/null | grep Codename | sed 's,Codename:\s\+,,')
PAIR := debs/$(ARCH)-$(DIST)
GENR := debs/all-$(DIST)
LOCALLIB := $(shell pwd)/locallib
INCLUDES := $(BUILDER)/lib
PERL := /usr/bin/perl -I $(INCLUDES)
PATH := $(LOCALLIB)/bin:$(PATH)
PWD := $(shell pwd)
CHECKOUT ?= $(PWD)/../app
PARAMS := --checkout $(CHECKOUT)

packages: .locallib deps elementalclinic-deb
	mkdir /tmp/newpackages -p
	mkdir $(PAIR) -p
	mkdir $(GENR) -p
	cp $(CHECKOUT)/debs/main/pool/cpan-lib/*/*/*.deb /tmp/newpackages/
	cp *.deb /tmp/newpackages/
	for i in `ls $(PAIR)/*.deb`; do \
		PACKAGE=`echo "$$i" | sed 's,.*/,,g'`; \
		rm -rf /tmp/newpackages/$$PACKAGE; \
	done
	for i in `ls $(GENR)/*.deb`; do \
		PACKAGE=`echo "$$i" | sed 's,.*/,,g'`; \
		rm -rf /tmp/newpackages/$$PACKAGE; \
	done
	mv /tmp/newpackages/*all.deb $(GENR)/ || true
	mv /tmp/newpackages/*86.deb $(PAIR)/ || true
	mv /tmp/newpackages/*amd64.deb $(PAIR)/ || true
	rm -rf /tmp/newpackages

.locallib:
	tar -zxvf local-lib.tar.gz
	cd local-lib; \
		perl Makefile.PL --bootstrap="../locallib" \
		make && make install
	eval $$(perl -I$(LOCALLIB)/lib/perl5 -Mlocal::lib="$(LOCALLIB)"); \
		yes | PATH="$(PATH)" perl -mCPAN -e "CPAN::force( 'install', 'CPANPLUS::Dist::Deb', 'File::ShareDir', 'namespace::autoclean', 'Moose', 'YAML::Syck', 'MooseX::Getopt', 'Path::Class', 'File::Path', 'File::Find', 'File::Spec', 'Module::Build', 'CPANPLUS::Dist::Build', 'DBI', 'DBD::Pg', 'Algorithm::C3' )"
	rm -rf local-lib
	touch .locallib

deps:
	eval $$(perl -I$(LOCALLIB)/lib/perl5 -Mlocal::lib="$(LOCALLIB)"); \
		cd "$(CHECKOUT)"; \
		perl Build.PL; \
		perl Build clean; \
		perl Build.PL; \
		PATH="$(PATH)" perl Build all-debs

elementalclinic-deb: .locallib
	yes | $(PERL) $(BUILDCMD) $(PARAMS) --addlib "$(LOCALLIB)/lib/perl5" $(PACKAGES)

clean:
	rm -rf .locallib locallib local-lib _build elementalclinic_*.*
