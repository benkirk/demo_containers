%.sqfs: Makefile
	TMPDIR=/var/tmp/$${USER}-charliecloud ; \
	mkdir -p $${TMPDIR} ; \
	rm -rf /var/tmp/$${USER}.ch ; \
	ch-image pull benjaminkirk/$(patsubst %.sqfs,%,$@):latest ; \
	ch-image list ; \
	ch-convert benjaminkirk/$(patsubst %.sqfs,%,$@):latest $@ ; \
	rm -rf /var/tmp/$${USER}.ch

%.sif: Makefile
	TMPDIR=/var/tmp/$${USER}-singularity ; \
	mkdir -p $${TMPDIR} ; \
	singularity pull $@ docker://benjaminkirk/$(patsubst %.sif,%,$@):latest

%-sandbox: %.sif
	TMPDIR=/var/tmp/$${USER}-singularity ; \
	mkdir -p $${TMPDIR} ; \
	singularity build --sandbox ./$@ ./$<

clean:
	rm -f *.sif *~ *.sh.o*

clobber:
	$(MAKE) clean
	chmod -R u+rwX ./*sandbox/ >/dev/null 2>&1
	rm -rf ./*sandbox/ ./mask/ *.sqfs
