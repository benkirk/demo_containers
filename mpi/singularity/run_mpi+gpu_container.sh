#!/bin/bash
#PBS -A SCSG0001
#PBS -q main
#PBS -j oe
#PBS -l walltime=01:00:00
#PBS -l select=2:ncpus=64:mpiprocs=16:ompthreads=4:ngpus=4

### Set temp to scratch
[ -d /glade/gust/scratch/${USER} ] && export TMPDIR=/glade/gust/scratch/${USER}/tmp && mkdir -p $TMPDIR

. config_env.sh >/dev/null 2>&1 || exit 1


status="SUCCESS"

#container_image=./rocky9-mpich-sandbox/
#container_image=./rocky9-libmesh-sandbox/
#container_image=./opensuse15-openhpc-sandbox/
container_image=./opensuse15-openhpc-cuda-sandbox/

mkdir -p $(pwd)/mask && echo "Empty Directory to hide container contents." > $(pwd)/mask/README

echo "ldd, container native:"
singularity exec \
        ${container_image} \
        ldd /opt/local/osu-micro-benchmarks-7.0.1/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_bibw

echo "ldd, container native:"
singularity exec \
        ${container_image} \
        ldd /opt/local/imb-2021.3/IMB-MPI1

echo "ldd, host bind:"
singularity exec \
        --bind /run \
        --bind /usr/lib64:/host/lib64 \
        --bind /opt/cray \
        --env LD_LIBRARY_PATH=${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/lib64:${LD_LIBRARY_PATH}:/host/lib64 \
        --env MPICH_SMP_SINGLE_COPY_MODE=NONE \
        --env MPICH_GPU_SUPPORT_ENABLED=1 \
        --env MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1 \
        ${container_image} \
        ldd /opt/local/osu-micro-benchmarks-7.0.1/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_bibw

#        --bind $(pwd)/hide:/usr/lib64/mpich/lib:ro \

[[ "x${PBS_NODEFILE}" != "x" ]] || { echo "Not in a PBS Job, exiting..."; exit 0; }


for exe in \
    /opt/local/osu-micro-benchmarks-7.0.1/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_bw \
    /opt/local/osu-micro-benchmarks-7.0.1/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_bibw \
    /opt/local/osu-micro-benchmarks-7.0.1/libexec/osu-micro-benchmarks/mpi/pt2pt/osu_latency \
    ; do

    echo && echo && echo "********* Intra-Node-GPU *****************"
    echo ${exe}
    mpiexec --np 2 --ppn 2 --no-transfer \
       get_local_rank \
       singularity exec \
          --bind /run \
          --bind /usr/lib64:/host/lib64 \
          --bind /opt/cray \
          --env LD_LIBRARY_PATH=${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/lib64:${LD_LIBRARY_PATH}:/host/lib64 \
          --env MPICH_SMP_SINGLE_COPY_MODE=NONE \
          --env MPICH_GPU_SUPPORT_ENABLED=1 \
          --env MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1 \
          --env LD_PRELOAD=/opt/cray/pe/mpich/8.1.21/gtl/lib/libmpi_gtl_cuda.so.0 \
          ${container_image} \
          ${exe} D D

    echo && echo && echo "********* Inter-Node-GPU *****************"
    echo ${exe}
    mpiexec --np 2 --ppn 1 --no-transfer \
       get_local_rank \
       singularity exec \
          --bind /run \
          --bind /usr/lib64:/host/lib64 \
          --bind /opt/cray \
          --env LD_LIBRARY_PATH=${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/lib64:${LD_LIBRARY_PATH}:/host/lib64 \
          --env MPICH_SMP_SINGLE_COPY_MODE=NONE \
          --env MPICH_GPU_SUPPORT_ENABLED=1 \
          --env MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1 \
          --env LD_PRELOAD=/opt/cray/pe/mpich/8.1.21/gtl/lib/libmpi_gtl_cuda.so.0 \
          ${container_image} \
          ${exe} D D
done


for exe in \
    /opt/local/osu-micro-benchmarks-7.0.1/libexec/osu-micro-benchmarks/mpi/collective/osu_alltoall \
    ; do

    echo && echo && echo "********* Intra-Node-GPU *****************"
    echo ${exe}
    mpiexec --np 4 --ppn 4 --no-transfer \
       get_local_rank \
       singularity exec \
          --bind /run \
          --bind /usr/lib64:/host/lib64 \
          --bind /opt/cray \
          --env LD_LIBRARY_PATH=${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/lib64:${LD_LIBRARY_PATH}:/host/lib64 \
          --env MPICH_SMP_SINGLE_COPY_MODE=NONE \
          --env MPICH_GPU_SUPPORT_ENABLED=1 \
          --env MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1 \
          --env LD_PRELOAD=/opt/cray/pe/mpich/8.1.21/gtl/lib/libmpi_gtl_cuda.so.0 \
          ${container_image} \
          ${exe} -d managed

    echo && echo && echo "********* Intra-Node-GPU *****************"
    echo ${exe}
    mpiexec --np 16 --ppn 16 --no-transfer \
       get_local_rank \
       singularity exec \
          --bind /run \
          --bind /usr/lib64:/host/lib64 \
          --bind /opt/cray \
          --env LD_LIBRARY_PATH=${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/lib64:${LD_LIBRARY_PATH}:/host/lib64 \
          --env MPICH_SMP_SINGLE_COPY_MODE=NONE \
          --env MPICH_GPU_SUPPORT_ENABLED=1 \
          --env MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1 \
          --env LD_PRELOAD=/opt/cray/pe/mpich/8.1.21/gtl/lib/libmpi_gtl_cuda.so.0 \
          ${container_image} \
          ${exe} -d managed

    echo && echo && echo "********* Inter-Node-GPU *****************"
    echo ${exe}
    mpiexec --np 8 --ppn 4 --no-transfer \
       get_local_rank \
       singularity exec \
          --bind /run \
          --bind /usr/lib64:/host/lib64 \
          --bind /opt/cray \
          --env LD_LIBRARY_PATH=${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/lib64:${LD_LIBRARY_PATH}:/host/lib64 \
          --env MPICH_SMP_SINGLE_COPY_MODE=NONE \
          --env MPICH_GPU_SUPPORT_ENABLED=1 \
          --env MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1 \
          --env LD_PRELOAD=/opt/cray/pe/mpich/8.1.21/gtl/lib/libmpi_gtl_cuda.so.0 \
          ${container_image} \
          ${exe} -d managed

    echo && echo && echo "********* Inter-Node-GPU *****************"
    echo ${exe}
    mpiexec --np 32 --ppn 16 --no-transfer \
       get_local_rank \
       singularity exec \
          --bind /run \
          --bind /usr/lib64:/host/lib64 \
          --bind /opt/cray \
          --env LD_LIBRARY_PATH=${CRAY_MPICH_DIR}/lib-abi-mpich:/opt/cray/pe/lib64:${LD_LIBRARY_PATH}:/host/lib64 \
          --env MPICH_SMP_SINGLE_COPY_MODE=NONE \
          --env MPICH_GPU_SUPPORT_ENABLED=1 \
          --env MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1 \
          --env LD_PRELOAD=/opt/cray/pe/mpich/8.1.21/gtl/lib/libmpi_gtl_cuda.so.0 \
          ${container_image} \
          ${exe} -d managed
done

echo && echo && echo ${status} $(date)
