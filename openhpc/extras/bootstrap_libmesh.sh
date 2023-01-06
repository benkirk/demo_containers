#!/bin/bash -l

[ -z ${MPI_BUILD} ] && exit 1

module load mpi/${MPI_BUILD}

# clone libmesh
export PETSC_DIR=/opt/local/petsc/3.16.6-${MPI_BUILD}
mkdir -p ~/codes && cd ~/codes || exit 1
git clone \
    --recurse-submodules \
    --branch v1.6.2 --depth 1 \
    https://github.com/libMesh/libmesh.git \
    && cd libmesh || exit 1
cd /home/plainuser/codes/libmesh/ && ./bootstrap || exit 1
./configure --prefix=/opt/local/libmesh/1.6.2-${MPI_BUILD} \
            --disable-dependency-tracking \
            --with-methods=opt \
            --enable-optional --disable-strict-lgpl \
            --enable-hdf5 --enable-hdf5-required \
    || exit 1
make --no-print-directory all || exit 1
make --no-print-directory install || exit 1
git clean -xdf . || exit 1
#rm -rf /home/plainuser/codes/libmesh/ || exit 1
cat <<EOF > ~/libmesh.sh || exit 1
export LIBMESH_DIR=/opt/local/libmesh/1.6.2-${MPI_BUILD}
EOF
