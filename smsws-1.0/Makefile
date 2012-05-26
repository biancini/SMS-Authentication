all: smsws

help:
	@echo "To compile run 'make' "
	@echo "To delete object file (*.o) and the executable run 'make clean' "

install: smsws
	./genfiles.sh
	mkdir -p ${sysconfdir}/../var/www/cgi-bin
	cp -rf cgi-bin/* ${sysconfdir}/../var/www/cgi-bin/
	mkdir -p ${sysconfdir}/../var/www/html
	cp -rf html/* ${sysconfdir}/../var/www/html/

smsws:
	@echo "Do not compile."

clean:
	@echo "Nothing to clean."
