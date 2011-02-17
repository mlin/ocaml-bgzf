### Configuration section

# The name of the Zlib library.  Usually -lz
ZLIB_LIB=-lz

# The directory containing the Zlib library (libz.a or libz.so)
ZLIB_LIBDIR=/usr/lib

# The directory containing the Zlib header file (zlib.h)
ZLIB_INCLUDE=/usr/include

###

OCAMLC=ocamlc -g
OCAMLOPT=ocamlopt
OCAMLDEP=ocamldep
OCAMLMKLIB=ocamlmklib

OBJS=BGZF.cmo bgzf_stubs.o bgzf.o

###

all: bgzip BGZF.cmi bgzf.cma bgzf.cmxa

bgzf.cma: $(OBJS)
	$(OCAMLMKLIB) -o bgzf -L$(ZLIB_LIBDIR) $(ZLIB_LIB) $(OBJS)
	
bgzf.cmxa: $(OBJS:.cmo=.cmx)
	$(OCAMLMKLIB) -o bgzf -L$(ZLIB_LIBDIR) $(ZLIB_LIB) $(OBJS:.cmo=.cmx)

bgzip: bgzip.o bgzf.o
	$(CC) $(CFLAGS) -o $@ bgzf.o bgzip.o $(ZLIB_LIB)
		
install: all
	ocamlfind install bgzf META *.mli *.a *.cmi *.cma *.cmxa $(wildcard *.so)
	
remove:
	ocamlfind remove bgzf
	
reinstall:
	make remove
	make install

test: reinstall
	ocamlfind ocamlopt -package unix,bgzf -linkpkg -o test test.ml
	./test

clean:
	rm -f *.cm*
	rm -f *.o *.a *.so
	rm -f bgzip test

.SUFFIXES: .mli .ml .cmo .cmi .cmx

.mli.cmi:
	$(OCAMLC) -c $<
.ml.cmo:
	$(OCAMLC) -c $<
.ml.cmx:
	$(OCAMLOPT) -c $<
.c.o:
	$(OCAMLC) -c -ccopt -g -ccopt -I$(ZLIB_INCLUDE) $<

# update to latest versions of upstream sources
PULL_BASE=http://samtools.svn.sourceforge.net/viewvc/samtools/trunk/samtools
PULL_FILES=khash.h bgzf.h bgzf.c bgzip.c
pull:
	for fn in $(PULL_FILES) ; do \
		rm -f $$fn ; \
		wget $(PULL_BASE)/$$fn ;\
	done
