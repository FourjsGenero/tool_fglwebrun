.SUFFIXES: .4gl .42m

.4gl.42m:
	fglcomp -M -W all $<


all: fglwebrun.42m fglwebrungdc.42m

demo: fglwebrun demo.42m
	./fglwebrun demo.42m a b

clean_prog:
	rm -f fglwebrun.42m

clean: clean_prog
	rm -f *.42?

dist: all 
