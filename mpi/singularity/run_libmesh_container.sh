#!/bin/bash
#PBS -A SCSG0001
#PBS -q main
#PBS -j oe
#PBS -l walltime=01:00:00
#PBS -l select=2:ncpus=128:mpiprocs=32:ompthreads=4

### Set temp to scratch
[ -d /glade/gust/scratch/${USER} ] && export TMPDIR=/glade/gust/scratch/${USER}/tmp && mkdir -p $TMPDIR

. config_env.sh >/dev/null 2>&1 || exit 1


status="SUCCESS"

container_image=./rocky9-libmesh-sandbox/
#container_image=./opensuse15-openhpc-libmesh-sandbox/

mkdir -p $(pwd)/mask && echo "Empty Directory to hide container contents." > $(pwd)/mask/README

echo "ldd, container native:"
singularity exec \
        ${container_image} \
        ldd /opt/local/libmesh/1.8.0-pre-mpich-x86_64/examples/introduction/ex4/example-opt

echo "ldd, host bind:"
singularity exec \
        --bind /run \
        --bind /usr/lib64:/host/lib64 \
        --bind /opt/cray \
        --env LD_LIBRARY_PATH=${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/lib64:${LD_LIBRARY_PATH}:/host/lib64 \
        --env MPICH_SMP_SINGLE_COPY_MODE=NONE \
        ${container_image} \
        ldd /opt/local/libmesh/1.8.0-pre-mpich-x86_64/examples/introduction/ex4/example-opt

#        --bind $(pwd)/hide:/usr/lib64/mpich/lib:ro \

[[ "x${PBS_NODEFILE}" != "x" ]] || { echo "Not in a PBS Job, exiting..."; exit 0; }

mpiexec --np 64 --ppn 32 --no-transfer \
  singularity \
     exec \
       --bind /run \
       --bind /var/run/palsd \
       --bind /usr/lib64:/host/lib64 \
       --bind /opt/cray \
       --env LD_LIBRARY_PATH=${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/lib64:${LD_LIBRARY_PATH}:/host/lib64 \
       --env MPICH_SMP_SINGLE_COPY_MODE=NONE \
       ${container_image} \
       /opt/local/libmesh/1.8.0-pre-mpich-x86_64/examples/introduction/ex4/example-opt -d 3 -n 50

echo && echo && echo ${status} $(date)
