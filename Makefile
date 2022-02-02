#!make
ifeq ($(OS),Windows_NT)
#SHELL := cmd
else
SHELL ?= /bin/bash
endif

JAR_VERSION := $(shell mvn -q -Dexec.executable="echo" -Dexec.args='$${project.version}' --non-recursive exec:exec -DforceStdout)
JAR_FILE := mnconvert-$(JAR_VERSION).jar

SRCDIR := src/test/resources
# Can change to
# SRCFILE := $(SRCDIR)/iso-tc154-8601-1-en.xml
SRCFILE := $(SRCDIR)/iso-rice-en.cd.mn.xml $(SRCDIR)/iso-tc154-8601-1-en.mn.xml

SRCFILESTS := $(SRCDIR)/rice-en.final.sts.xml

SRCRFCDIR := rfcsources
SRCRFCMASK := rfc865*.xml

DESTDIR := documents
DESTSTSXML := $(patsubst %.mn.xml,%.sts.xml,$(patsubst src/test/resources/%,documents/%,$(SRCFILE)))
DESTSTSHTML := $(patsubst %.xml,%.html,$(DESTSTSXML))

DESTMNADOC := $(patsubst %.sts.xml,%.mn.adoc,$(patsubst src/test/resources/%,documents/%,$(SRCFILESTS)))

SAXON_URL := https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.1/Saxon-HE-10.1.jar
STS2HTMLXSL := https://www.iso.org/schema/isosts/resources/isosts2html_standalone.xsl

ifeq ($(OS),Windows_NT)
  CMD_AND = &
else
  CMD_AND = ;
endif

all: target/$(JAR_FILE) documents documents.html

src/test/resources/iso-tc154-8601-1-en.mn.xml: tests/iso-8601-1/site/documents/iso-tc154-8601-1-en.xml
	cp $< $@

tests/iso-8601-1/site/documents/iso-tc154-8601-1-en.xml:
	cd tests/iso-8601-1 && metanorma site generate --agree-to-terms
#ifeq ($(OS),Windows_NT)
#	$(MAKE) -C tests/iso-8601-1 -f Makefile.win all SHELL=cmd
#else	
#	$(MAKE) -C tests/iso-8601-1 all
#endif

src/test/resources/iso-rice-en.cd.mn.xml: tests/mn-samples-iso/documents/international-standard/rice-en.cd.xml
	cp $< $@

#tests/mn-samples-iso/documents/international-standard/rice-en.cd.xml:
#ifeq ($(OS),Windows_NT)
#	$(MAKE) -C tests/mn-samples-iso -f Makefile.win all SHELL=cmd
#else
#	$(MAKE) -C tests/mn-samples-iso all
#endif

documents/%.mn.xml: src/test/resources/%.mn.xml
	cp $< $@

target/$(JAR_FILE):
	mvn --settings settings.xml -DskipTests clean package shade:shade

testMN2STS: tests/mn-samples-iso/documents/international-standard/rice-en.cd.xml target/$(JAR_FILE)
	mvn -DinputMNXML=$< --settings settings.xml test surefire-report:report

testSTS2MN:
	mvn -DinputSTSXML=$(SRCFILESTS) --settings settings.xml test surefire-report:report


deploy:
	mvn --settings settings.xml -Dmaven.test.skip=true clean deploy shade:shade

documents/%.sts.html: documents/%.sts.xml saxon.jar
	java -jar saxon.jar -s:$< -xsl:$(STS2HTMLXSL) -o:$@

documents/%.sts.xml: documents/%.mn.xml | target/$(JAR_FILE) documents
	java -jar target/$(JAR_FILE) $< --output $@ --output-format iso

mn2stsDTD_NISO: $(DESTSTSXML) target/$(JAR_FILE) | documents
	@$(foreach xml,$(DESTSTSXML),java -jar target/$(JAR_FILE) $(xml) --check-type dtd-niso $(CMD_AND))

mn2stsDTD_ISO: $(DESTSTSXML) target/$(JAR_FILE) | documents
	@$(foreach xml,$(DESTSTSXML),java -jar target/$(JAR_FILE) $(xml) --check-type dtd-iso $(CMD_AND))

documents.adoc: target/$(JAR_FILE) documents
	java -jar $< ${SRCFILESTS} --output ${DESTMNADOC}

xml2rfc.adoc: target/$(JAR_FILE) rfcsources documents
ifeq ($(OS),Windows_NT)
	for /r %%f in ($(SRCRFCDIR)/*.xml) do java -jar target/$(JAR_FILE) $(SRCRFCDIR)/%%~nxf --output $(DESTDIR)/%%~nf.adoc
else
	for f in $(SRCRFCDIR)/*.xml; do fout=$${f##*/}; java -jar target/$(JAR_FILE) $$f --output $(DESTDIR)/$${fout%.*}.adoc  ; done
endif

rfcsources:
	wget -r -l 1 -nd -A ${SRCRFCMASK} -R rfc-*.xml -P ${SRCRFCDIR} https://www.rfc-editor.org/rfc/


saxon.jar:
	curl -sSL $(SAXON_URL) -o $@

documents.rxl: $(DESTSTSHTML) | bundle
	bundle exec relaton concatenate \
	  -t "mnconvert samples" \
		-g "Metanorma" \
		documents $@

bundle:
	bundle

documents.html: documents.rxl
	bundle exec relaton xml2html documents.rxl


documents:
	mkdir $@

clean:
	mvn clean
	rm -rf documents

publish: published
published: documents.html documents.adoc xml2rfc.adoc
	mkdir $@
ifeq ($(OS),Windows_NT)
	xcopy documents $@\ /E
else
	cp -a documents $@
endif

.PHONY: all clean test deploy version publish mn2stsDTD_NISO mn2stsDTD_ISO
