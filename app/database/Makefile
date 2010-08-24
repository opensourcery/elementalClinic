# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# global variables
CONFIG=../ # CONFIG isn't necessary for configuration, but is for test data
LIB=../lib/
TESTDATA=../../testdata
LOG=./make.log
EMC_CONFIG := perl -I$(LIB) ../script/elementalclinic_config --branch=..
DB      := $(shell $(EMC_CONFIG) dbname)
DB_USER := $(shell $(EMC_CONFIG) dbuser)
DB_PORT := $(shell $(EMC_CONFIG) port)
PGPASSFILE := $(shell $(EMC_CONFIG) passwd)
DB_HOST := $(shell $(EMC_CONFIG) host)
DB_ARGS := -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER)
PSQL    := env PGPASSFILE=$(PGPASSFILE) psql -d $(DB) -q $(DB_ARGS)
# url is just a handy way of summarizing connect info, not actually used by any
# programs
URL     := postgres://$(DB_USER)@$(DB_HOST):$(DB_PORT)/$(DB)
DEV_VERSION=443
RELEASE_SQL := release/$(DB)-$(DEV_VERSION).sql

DEPRECATED:
	@echo This target has been deprecated.

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# functions
# `perl -e 01` is to make sure we return ok.  must be a better way
squirt_sql_and_catch_errors=@$(PSQL) < $(1) 2>&1 | tee $(LOG) \
	| grep -v 'NOTICE' \
	| grep -v setval \
	| grep -v '\-\-\-\-\-' \
	| grep -v '^$$' \
	| grep -v '[:space:]*[0-9]$$' \
	| grep -v '\(1 row\)'; \
	grep 'ERROR' $(LOG); \
	perl -e 0

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# targets
default:
	@echo "would be working on database '$(DB)', but you didn't specify a target"
	@grep '^[^[:space:]]*:[ [:alnum:]_-]*$$' Makefile

setup:
	@cd .. && perl -I lib script/elementalclinic_migration -R -s 0
	@cd .. && perl -I lib script/elementalclinic_migration --to 350

clean-stable: setup

set-db-to-35:
	@cd .. && perl -I lib script/elementalclinic_migration -s 350

update-35-to-40: set-db-to-35 patch-to-40

patch-to-40:
	@cd .. && perl -I lib script/elementalclinic_migration --to 400

patch-to-dev: 
	@cd .. && perl -I lib script/elementalclinic_migration --to $(DEV_VERSION)

release-dump:
	@rm -f release/$(DB)-*.sql
	@echo "dump <<< $(URL)"
	@echo "dump >>> $(RELEASE_SQL)"
	@mkdir -p $(shell dirname $(RELEASE_SQL))
	@pg_dump $(DB_ARGS) $(DB) -f $(RELEASE_SQL)

import-release:
	@dropdb -e $(DB_ARGS) $(DB) || true
	@createdb -e $(DB_ARGS) $(DB)
	@echo "import <<< $(RELEASE_SQL)"
	@echo "import >>> $(URL)"
	@$(PSQL) -f $(RELEASE_SQL) > /dev/null

import-or-dump:
	@if [ -e $(RELEASE_SQL) ]; \
		then make import-release; \
		else \
			rm -f release/*.sql; \
			make clean-dev; \
			(cd .. && perl -Ilib script/elementalclinic_fixture_import -f fixtures/base-sys); \
			make release-dump; \
	fi

patch-to-production:
	$(call squirt_sql_and_catch_errors,development/claims_processors.sql)
	$(call squirt_sql_and_catch_errors,development/validation_rules.sql)

clean-dev: clean-stable patch-to-dev

clean-production: clean-dev patch-to-production

dbconnect:
	$(PSQL)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# stuff for dumping data
dump-validation-rules:
	@pg_dump $(DB_ARGS) --data-only --inserts --column-inserts --no-owner --no-acl --table validation_rule --file development/validation_rules.sql $(DB)

dump-claims-processors:
	@pg_dump $(DB_ARGS) --data-only --inserts --column-inserts --no-owner --no-acl --table claims_processor --file development/claims_processors.sql $(DB)

dump-permissions-patch:
	@$(PSQL) --command "\d" | grep public

fix-permissions:
	@echo `bin/permissions_patch.pl "$(DB_USER) $(DB)" clinic` | $(PSQL)

insert-validation-rules:
	$(call squirt_sql_and_catch_errors,development/validation_rules.sql)

insert-claims_processors:
	$(call squirt_sql_and_catch_errors,development/claims_processors.sql)

dump-schema:
	@pg_dump $(DB_ARGS) --schema-only --no-owner --no-acl $(DB)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# variables to pass to testdata makefile
VARS=DB_USER=$(DB_USER) DB='$(DB)' LIB=$(LIB) CONFIG=$(CONFIG) TESTDATA=$(TESTDATA)
testdata-:
	@echo must specify which test data

testdata-test:
	@make -f $(TESTDATA)/Makefile testdata-test $(VARS)

testdata-jazz: DEPRECATED

testdata-huge: recreate
	@make -f $(TESTDATA)/Makefile testdata-huge $(VARS)

testdata-rolodex-dirty: clean-stable
	@make -f $(TESTDATA)/Makefile testdata-rolodex-dirty $(VARS)

# sets up a sample billing cycle in testdata-jazz. no validation.
testdata-billingcycle: testdata-jazz testdata-clinic
	@perl -I$(LIB) ../bin/billingcycle_data.pl

# sets up a sample billing cycle in testdata-jazz and runs system validation 
testdata-billingcycle-system: testdata-jazz testdata-clinic
	@perl -I$(LIB) ../bin/billingcycle_data.pl system

# sets up a sample billing cycle in testdata-jazz and runs system and payer validation 
testdata-billingcycle-payer: testdata-jazz testdata-clinic
	@perl -I$(LIB) ../bin/billingcycle_data.pl payer

# sets up a sample billing cycle in testdata-jazz, runs system and payer 
# validation, creates the billing files (hcfa and/or 837) and marks them as billed
testdata-billingcycle-billed: testdata-jazz testdata-clinic
	@perl -I$(LIB) ../bin/billingcycle_data.pl billed

# sets up a sample billing cycle in testdata-jazz, runs system and payer
# validation, creates the billing files, marks them as billed,
# and processes a sample payment for the billed notes
testdata-payment: testdata-jazz testdata-clinic fix-permissions
	@perl -I$(LIB) ../bin/payment_data.pl

# makes a medicaid case available for testing
# FIXME this is a bit of a hack at the moment, probably unstable for any other use
testdata-payment-medicaid: testdata-payment
	$(call squirt_sql_and_catch_errors, development/update_billing_file_for_medicaid.sql)

# sets up a sample billing cycle in testdata-jazz, runs system and payer
# validation, creates the billing files, marks them as billed, processes
# a sample payment, and then does all of this again for a second billing
# cycle on the same notes.
testdata-payment2: testdata-payment
	@perl -I$(LIB) ../bin/payment_data.pl 2

# same as above, then runs 3rd billing cycle
testdata-payment3: testdata-payment
	@perl -I$(LIB) ../bin/payment_data.pl 2
	@perl -I$(LIB) ../bin/payment_data.pl 3

# same as above, then runs 4th billing cycle
testdata-payment4: testdata-payment
	@perl -I$(LIB) ../bin/payment_data.pl 2
	@perl -I$(LIB) ../bin/payment_data.pl 3
	@perl -I$(LIB) ../bin/payment_data.pl 4

# sets up billing cycle 2 so that a note does not show up in billing cycle 1 but shows up in 2.
# (note is identical to a note in cycle 1)
testdata-billingcycle-billed_identical: testdata-jazz testdata-clinic fix-permissions
	@perl -I$(LIB) ../bin/billingcycle_data.pl billed_identical

# same as testdata-billingcycle-billed
testdata-nopayment: testdata-jazz testdata-clinic
	@perl -I$(LIB) ../bin/payment_data.pl 1 no_payment

# use to import the clinic's ids and passwords from a separate file,
# in order to test ECS communication with testdata-jazz.
testdata-clinic:
	$(call squirt_sql_and_catch_errors,clinic.sql)

# sets up a sample billing cycle in testdata-huge. no validation.
testdata-billinghuge: testdata-huge testdata-huge-claimsproc
	@perl -I$(LIB) ../bin/billingcycle_huge.pl

# sets up a sample billing cycle in testdata-huge and runs system validation 
testdata-billinghuge-system: testdata-huge testdata-huge-claimsproc
	@perl -I$(LIB) ../bin/billingcycle_huge.pl system

# sets up a sample billing cycle in testdata-huge and runs system and payer validation 
testdata-billinghuge-payer: testdata-huge testdata-huge-claimsproc
	@$(PSQL) --command "update client_insurance set insured_relationship_id = 1;" # hack to fix obfu data for now TODO remove
	@perl -I$(LIB) ../bin/billingcycle_huge.pl payer

# sets up a sample billing cycle in testdata-huge, runs system and payer 
# validation, creates the billing files (hcfa and/or 837) and marks them as billed
testdata-billinghuge-billed: testdata-huge testdata-huge-claimsproc
	@$(PSQL) --command "update client_insurance set insured_relationship_id = 1;" # hack to fix obfu data for now TODO remove
	@perl -I$(LIB) ../bin/billingcycle_huge.pl billed

# sets up a sample billing cycle in testdata-huge, runs system and payer
# validation, creates the billing files, marks them as billed,
# and processes a sample payment for the billed notes
testdata-billinghuge-payment: testdata-huge testdata-huge-claimsproc
	@$(PSQL) --command "update client_insurance set insured_relationship_id = 1;" # hack to fix obfu data for now TODO remove
	@perl -I$(LIB) ../bin/billingcycle_huge.pl payment

# use to import the clinic's ids and passwords from a separate file,
# in order to test ECS communication with testdata-huge.
testdata-huge-claimsproc:
	$(call squirt_sql_and_catch_errors,huge-claimsproc.sql)
