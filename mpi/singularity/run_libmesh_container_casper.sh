#!/bin/bash
#PBS -A SCSG0001
#PBS -q casper
#PBS -j oe
#PBS -l walltime=01:00:00
#PBS -l select=2:ncpus=8:mpiprocs=8:ompthreads=1


. config_env.sh >/dev/null 2>&1 || exit 1


status="SUCCESS"

#container_image=./rocky9-libmesh-sandbox/
#container_image=./opensuse15-openhpc-libmesh-sandbox/
container_image="ncar-casper-openhpc-libmesh.sif"

echo "ldd, container native:"
singularity \
    --quiet \
    exec \
        ${container_image} \
        ldd /opt/local/libmesh/1.8.0-pre-openmpi4-x86_64/examples/introduction/ex4/example-opt

# echo "ldd, host bind:"
# singularity exec \
#         ${container_image} \
#         ldd /opt/local/libmesh/1.8.0-pre-openmpi4-x86_64/examples/introduction/ex4/example-opt

[[ "x${PBS_NODEFILE}" != "x" ]] || { echo "Not in a PBS Job, exiting..."; exit 0; }

mpiexec \
    singularity \
    --quiet \
    exec \
    --env LD_LIBRARY_PATH="/opt/ohpc/pub/libs/hwloc/lib:/opt/ohpc/pub/mpi/ucx-ohpc/1.15.0/lib:" \
    -B /glade/campaign \
    -B /glade/cheyenne/scratch \
    -B /glade/derecho/scratch \
    -B /glade/work \
    -B /glade/u \
    -B /local_scratch \
    ${container_image} \
    /opt/local/libmesh/1.8.0-pre-openmpi4-x86_64/examples/introduction/ex4/example-opt -d 3 -n 50

echo && echo && echo ${status} $(date)
