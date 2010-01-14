PERL := perl -I${CHECKOUT}/lib -I${ADDLIB}

default:

install:
	$(PERL) $(CHECKOUT)/script/elementalclinic_setup -v --destdir ${DESTDIR} \
		--www-user www-data \
		--db-user elementalclinic \
		--db-pass ''
	mkdir -p "${DESTDIR}/etc/apache2/sites-available"
	mkdir -p "${DESTDIR}/etc/apache2/sites-enabled"
	mkdir -p "${DESTDIR}/usr/share/elementalclinic"
	mkdir -p "${DESTDIR}/usr/share/doc/elementalclinic"
	cp -r "fixtures" "${DESTDIR}/usr/share/elementalclinic"
	cp "etc/httpd.conf"  "${DESTDIR}/etc/apache2/sites-available/elementalclinic.conf"
	# these are all only necessary for ease of upgrading
	cp "etc/startup.pl"  "${DESTDIR}/etc/elementalclinic/startup.pl"
	cp "etc/report.yaml" "${DESTDIR}/etc/elementalclinic/report.yaml"
	cp "etc/log.conf"    "${DESTDIR}/etc/elementalclinic/log.conf"
	mkdir -p             "${DESTDIR}/etc/elementalclinic/ecs"
	mkdir -p             "${DESTDIR}/etc/elementalclinic/hcfa"
	cp -a etc/ecs/*      "${DESTDIR}/etc/elementalclinic/ecs"
	cp -a etc/hcfa/*     "${DESTDIR}/etc/elementalclinic/hcfa"
	cp INSTALL			 "${DESTDIR}/usr/share/doc/elementalclinic/INSTALL"

clean:
	@echo "Nothing..."
