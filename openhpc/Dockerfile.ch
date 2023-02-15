FROM opensuse/leap
#MAINTAINER Ben Kirk <benjamin.s.kirk@gmail.com>

COPY extras/docker-clean /usr/bin/docker-clean

ARG MPI_FAMILY=mpich
ARG MPI_FAMILY_VARIANT=mpich-ofi
ARG COMPILER_VERSION=gnu12

# Basic OpenHPC development environment setup, derived from Install_guide-Leap_15-Warewulf-SLURM-2.4-x86_64.pdf
RUN echo "basic zypper setup" \
    && set -x \
    && docker-clean \
    && useradd plainuser  \
    && zypper -n install curl xz \
    && cd /tmp/ && curl -O http://repos.openhpc.community/OpenHPC/2/Leap_15/x86_64/ohpc-release-2-1.leap15.x86_64.rpm && zypper -n --no-gpg-checks install ./ohpc-release-2-1.leap15.x86_64.rpm && rm -f ./ohpc-release-2-1.leap15.x86_64.rpm \
    && zypper -n --no-gpg-checks update \
    && zypper -n --no-gpg-checks install ohpc-base \
    && zypper -n --no-gpg-checks install lmod-ohpc nhc-ohpc ohpc-autotools \
    && zypper -n --no-gpg-checks install ${COMPILER_VERSION}-compilers-ohpc \
    && zypper -n --no-gpg-checks install hwloc-ohpc valgrind-ohpc \
    && zypper -n --no-gpg-checks install ${MPI_FAMILY_VARIANT}-${COMPILER_VERSION}-ohpc \
    && zypper -n --no-gpg-checks install lmod-defaults-${COMPILER_VERSION}-${MPI_FAMILY_VARIANT}-ohpc \
    && zypper search petsc-${COMPILER_VERSION} trilinos-${COMPILER_VERSION} \
    && docker-clean

# Addons Ben wants to play with
RUN echo "Extra packages" \
    && set -x \
    && zypper -n --no-gpg-checks install \
              boost-${COMPILER_VERSION}-${MPI_FAMILY}-ohpc \
              fftw-${COMPILER_VERSION}-${MPI_FAMILY}-ohpc \
              gsl-${COMPILER_VERSION}-ohpc \
              hdf5-${COMPILER_VERSION}-ohpc phdf5-${COMPILER_VERSION}-${MPI_FAMILY}-ohpc \
              netcdf-${COMPILER_VERSION}-${MPI_FAMILY}-ohpc \
              openblas-${COMPILER_VERSION}-ohpc \
    && docker-clean

# Addons Ben wants to play with
RUN echo "More extra packages" \
    && set -x \
    && zypper -n --no-gpg-checks install \
              petsc-${COMPILER_VERSION}-${MPI_FAMILY}-ohpc \
              git tar \
    && docker-clean

# Prevent mpicxx from linking -lmpicxx, which we do not need, and cannot use on our Cray-EX
RUN sed -i 's/cxxlibs="-lmpicxx"/cxxlibs= #"-lmpicxx"/g' /opt/ohpc/pub/mpi/${MPI_FAMILY_VARIANT}-${COMPILER_VERSION}-ohpc/3.4.3/bin/mpicxx

COPY extras/hello_world_mpi.C /home/plainuser/
COPY extras/bootstrap_libmesh.sh /home/plainuser/
COPY extras/install_benchmarks.sh /home/plainuser/

RUN mkdir -p /opt/local /opt/cray /glade /host
#    && chown -R plainuser: /home/plainuser/ /opt/local

#USER plainuser
#SHELL ["/bin/bash", "-lc"]

RUN whoami \
    && bash -lc "module avail && module load ${MPI_FAMILY} && sh /home/plainuser/install_benchmarks.sh"

# Local Variables:
# mode: sh
# End:
