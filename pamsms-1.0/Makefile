all: pammodule pamwrap

help:
	@echo "To compile run 'make' "
	@echo "To delete object file (*.o) and the executable run 'make clean' "

install: pammodule pamwrap
	mkdir -p ${libdir}/security
	cp -f pam_retisms.so ${libdir}/security/pam_retisms.so
	mkdir -p ${sysconfdir}/pam.d
	cp -f retisms ${sysconfdir}/pam.d/retisms
	mkdir -p ${bindir}
	cp -f pamwrap ${bindir}/pamwrap

pammodule:
	gcc -Wall -fPIC -c pam_retisms.c
	ld -x --shared -o pam_retisms.so pam_retisms.o -lpam
	rm -f pam_retisms.o

pamwrap:
	gcc -o pamwrap pamwrap.c -lpam

clean:
	rm -f pam_retisms.so pamwrap 
