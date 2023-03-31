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

osu-benchmarks/$(NCAR_BUILD_ENV): Makefile
	rm -rf $@
	prefix=$$(pwd)/$@ ; \
	  module load cuda ; \
	  cd /tmp ; \
	  curl -Sl  https://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-7.0.1.tar.gz | tar xz ; \
	  cd osu-micro-benchmarks-7.0.1 ; \
	  ./configure --prefix=$${prefix} CXX=$$(which mpicxx) CC=$$(which mpicc) FC=$$(which mpif90) F77=$$(which mpif77) --enable-cuda --with-cuda=$(CUDA_HOME) NVCCFLAGS="-allow-unsupported-compiler" ; \
	  make -j 8 V=0 && make install

results:
	for stub in "mpi+gpu" "mpi+cpu" ; do \
	  for file in *$${stub}*.sh.o*[0-9]; do \
	    [ -f $${file} ] && echo $${file} || continue ; \
	    awk '/# --> BEGIN execution/{flag=1;next}/# --> END execution/{flag=0}flag' $${file} > $${file}.results ; \
            sed -i 's/Global Rank/# Global Rank/g' $${file}.results ; \
	    cp $${file}.results results-$${stub}.latest ; \
	  done ; \
	  [ -f results-$${stub}.latest ] && cat results-$${stub}.latest || continue ; \
	done
