ifdef windir
WINDIR=$(windir)
endif

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

ifdef WINDIR

define _env
set $(1)=$(2)&&
endef
FGLWEBRUN=fglwebrun

else

define _env
$(1)=$(2) 
endef
FGLWEBRUN=./fglwebrun

endif
GBCOPT=$(call _env,FGLGBCDIR,$(FGLGBCDIR))
UROPT=$(call _env,FGLPROFILE,universal)

all: fglwebrun.42m fglwebrungdc.42m runonserver.42m getgdcpath.42m

demo: fglwebrun demo.42f demo.42m
#	FILTER=ALL $(FGLWEBRUN) demo a b
	$(FGLWEBRUN) demo a b

#show cases how one could use fgldeb for debugging
fgldeb_demo: fglwebrun fgldeb demo.42f demo.42m
	fglcomp -M demo&&$(FGLWEBRUN) fgldeb/fgldeb demo a b

fgldeb:
	git clone https://github.com/FourjsGenero/tool_fgldeb fgldeb


gmiurdemo: fglwebrun demo.42f demo.42m
	$(call _env,GMI,1)$(GBCOPT)$(UROPT)$(FGLWEBRUN) demo a b

gmidemo: fglwebrun demo.42f demo.42m
	$(call _env,GMI,1)$(FGLWEBRUN) demo a b

gdcdemo: fglwebrun demo.42f demo.42m
#note you must specify GDC
ifndef WINDIR
	if [ -z $(GDC) ]; then echo "GDC not set"; exit 1; fi
endif
	$(call _env,GDC,$(GDC))$(FGLWEBRUN) demo a b

gdcurdemo: fglwebrun demo.42f demo.42m
#note you must specify GDC
ifndef WINDIR
	if [ -z $(GDC) ]; then echo "GDC not set"; exit 1; fi
endif
	$(call _env,GDC,$(GDC))$(GBCOPT)$(UROPT)$(FGLWEBRUN) demo a b

echo:
	@echo "FGLGBCDIR=$(FGLGBCDIR)"
	@echo "GBCOPT=$(GBCOPT)"
	@echo "UROPT=$(UROPT)"
	@echo "make=$(MAKE)"

clean_prog:
	rm -f fglwebrun.42m fglwebrungdc.42m runonserver.42m getgdcpath.42m

clean: clean_prog
	rm -f *.42?

dist: all 
