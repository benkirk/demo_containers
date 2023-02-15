%.sqfs: Makefile
	TMPDIR=/var/tmp/$${USER}-charliecloud ; \
	mkdir -p $${TMPDIR} ; \
	rm -rf /var/tmp/$${USER}.ch ; \
	ch-image pull benjaminkirk/$(patsubst %.sqfs,%,$@):0.0.1 ; \
	ch-image list ; \
	ch-convert benjaminkirk/$(patsubst %.sqfs,%,$@):0.0.1 $@ ; \
	rm -rf /var/tmp/$${USER}.ch

%.sif: Makefile
	TMPDIR=/var/tmp/$${USER}-singularity ; \
	mkdir -p $${TMPDIR} ; \
	singularity pull $@ docker://benjaminkirk/$(patsubst %.sif,%,$@):0.0.1

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
