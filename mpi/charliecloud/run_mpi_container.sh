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

#container_image=./rocky9-mpich-sandbox/
#container_image=./rocky9-libmesh-sandbox/
container_image=./opensuse15-openhpc.sqfs

mkdir -p $(pwd)/mask && echo "Empty Directory to hide container contents." > $(pwd)/mask/README

echo "ldd, container native:"
ch-run \
        ${container_image} -- \
        ldd /opt/local/osu-micro-benchmarks-7.0.1/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_bibw

echo "ldd, container native:"
ch-run \
        ${container_image} -- \
        ldd /opt/local/imb-2021.3/IMB-MPI1

echo "ldd, host bind:"
CH_LD_LIBRARY_PATH="${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/pmi/6.1.9/lib:/opt/cray/pe/pals/1.2.4/lib:${LD_LIBRARY_PATH}:/host/lib64"
CH_LD_LIBRARY_PATH=${CH_LD_LIBRARY_PATH//opt\/cray/mnt\/0}   # replace opt/cray with mnt/0
CH_LD_LIBRARY_PATH=${CH_LD_LIBRARY_PATH//host\/lib64/mnt\/1} # replace host/lib64 with mnt/1
echo CH_LD_LIBRARY_PATH=${CH_LD_LIBRARY_PATH}
ch-run \
        --bind=/run \
        --bind=/opt/cray:/mnt/0 \
        --bind=/usr/lib64:/mnt/1 \
        --set-env=LD_LIBRARY_PATH=${CH_LD_LIBRARY_PATH} \
        --set-env=MPICH_SMP_SINGLE_COPY_MODE=NONE \
        ${container_image} -- \
        ldd /opt/local/osu-micro-benchmarks-7.0.1/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_bibw

#        --bind $(pwd)/hide:/usr/lib64/mpich/lib:ro \

[[ "x${PBS_NODEFILE}" != "x" ]] || { echo "Not in a PBS Job, exiting..."; exit 0; }


for exe in \
    /opt/local/imb-2021.3/IMB-MPI1 \
    /opt/local/imb-2021.3/IMB-P2P \
    /opt/local/osu-micro-benchmarks-7.0.1/libexec/osu-micro-benchmarks/mpi/collective/osu_alltoall \
    ; do

    mpiexec --np 64 --ppn 32 --no-transfer \
      ch-run \
        --bind=/run \
        --bind=/opt/cray:/mnt/0 \
        --bind=/usr/lib64:/mnt/1 \
        --set-env=LD_LIBRARY_PATH=${CH_LD_LIBRARY_PATH} \
        --set-env=MPICH_SMP_SINGLE_COPY_MODE=NONE \
        ${container_image} -- \
        ${exe}
done

echo && echo && echo ${status} $(date)
