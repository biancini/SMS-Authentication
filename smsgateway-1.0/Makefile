all: smsgateway_install

help:
	@echo "To compile run 'make' "
	@echo "To delete object file (*.o) and the executable run 'make clean' "

install: smsgateway_install
	./genfiles.sh "${datadir}"
	mkdir -p ${sysconfdir}/modem
	cp -rf smsgateway/etc/* ${sysconfdir}/modem
	rm -rf smsgateway/etc
	mkdir -p ${sysconfdir}/init.d
	mv smsgateway/bin/smsgateway ${sysconfdir}/init.d/smsgateway
	mkdir -p ${datadir}
	cp -rf smsgateway ${datadir}/

smsgateway_install:
	@echo "Do not compile."

clean:
	@echo "Nothing to clean."
