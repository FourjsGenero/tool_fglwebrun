%.42f: %.per 
	fglform -M -Wall $<

%.42m: %.4gl 
	fglcomp -M -r -Wall $*


ifndef FGLGBCDIR
ifneq ($(wildcard $(FGLDIR)/web_utilities/gbc/gbc),)
  FGLGBCDIR=$(FGLDIR)/web_utilities/gbc/gbc
  $(echo found a GBC in $(FGLGBCDIR))
endif
endif

GBCOPT=FGLGBCDIR=$(FGLGBCDIR)

all: fglwebrun.42m fglwebrungdc.42m runonserver.42m

demo: fglwebrun demo.42f demo.42m
#	FILTER=ALL ./fglwebrun demo a b
	./fglwebrun demo a b

gmiurdemo: fglwebrun demo.42f demo.42m
	$(GBCOPT) GMI=1 FGLPROFILE=universal ./fglwebrun demo a b

gdcurdemo: fglwebrun demo.42f demo.42m
#note you must specify GDC
	if [ -z $(GDC) ]; then echo "GDC executable not set"; exit 1; fi
	GDC=$(GDC) $(GBCOPT) FGLPROFILE=universal ./fglwebrun demo a b

echo:
	echo "FGLGBCDIR=$(FGLGBCDIR)"

clean_prog:
	rm -f fglwebrun.42m fglwebrungdc.42m runonserver.42m

clean: clean_prog
	rm -f *.42?

dist: all 
