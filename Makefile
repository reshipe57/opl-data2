.PHONY: builddir datadist sqlite check probe-quick probe deploy clean

DATADIR := meet-data
BUILDDIR := build

PLFILE := entries.csv
MEETFILE := meets.csv
MEETFILEJS := meets.js

DATE := $(shell date --iso-8601)
DATADIR := ${BUILDDIR}/openpowerlifting-${DATE}

all: csv server

builddir:
	mkdir -p '${BUILDDIR}'

# Cram all the data into huge CSV files. New hotness.
csv: builddir
	cargo run --bin checker -- --compile

# Build the CSV file hosted on the Data page for use by humans.
# The intention is to make it easy to use for people on Windows.
data: csv
	mkdir -p "${DATADIR}"
	scripts/make-data-distribution
	mv "${BUILDDIR}/openpowerlifting.csv" "${DATADIR}/openpowerlifting-${DATE}.csv"
	cp LICENSE-DATA '${DATADIR}/LICENSE.txt'
	cp docs/data-readme.md '${DATADIR}/README.txt'
	rm -f "${BUILDDIR}/openpowerlifting-latest.zip"
	cd "${BUILDDIR}" && zip -r "openpowerlifting-latest.zip" "openpowerlifting-${DATE}"

# Optionally build an SQLite3 version of the database.
sqlite: csv
	scripts/prepare-for-sqlite
	scripts/compile-sqlite

server: csv
	$(MAKE) -C server

# Make sure that all the fields in the CSV files are in expected formats.
check:
	cargo run --bin checker
	tests/check-sex-consistency
	tests/check-lifter-data
	tests/check-duplicates
	tests/check-python-style

# Run all probes in a quick mode that only shows a few pending meets.
probe-quick:
	find "${DATADIR}" -name "*-probe" | sort | parallel --timeout 5m --keep-order --will-cite "{} --quick"

# Run all probes.
probe:
	find "${DATADIR}" -name "*-probe" | sort | parallel --timeout 5m --keep-order --will-cite

# Push the current version to the webservers.
deploy:
	$(MAKE) -C server/ansible

clean:
	rm -rf '${BUILDDIR}'
	rm -rf 'scripts/__pycache__'
	rm -rf 'tests/__pycache__'
	rm -rf '${DATADIR}/apf/__pycache__'
	rm -rf '${DATADIR}/cpu/__pycache__'
	rm -rf '${DATADIR}/ipf/__pycache__'
	rm -rf '${DATADIR}/nasa/__pycache__'
	rm -rf '${DATADIR}/nipf/__pycache__'
	rm -rf '${DATADIR}/nsf/__pycache__'
	rm -rf '${DATADIR}/pa/__pycache__'
	rm -rf '${DATADIR}/rps/__pycache__'
	rm -rf '${DATADIR}/spf/__pycache__'
	rm -rf '${DATADIR}/thspa/__pycache__'
	rm -rf '${DATADIR}/usapl/__pycache__'
	rm -rf '${DATADIR}/wrpf/__pycache__'
	$(MAKE) -C server clean
	rm -rf target
