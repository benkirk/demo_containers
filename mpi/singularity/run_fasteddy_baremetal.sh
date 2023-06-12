#!/bin/bash
#PBS -A SCSG0001
#PBS -q main
#PBS -j oe
#PBS -k oed
#PBS -l walltime=02:00:00
#PBS -l select=3:ncpus=64:mpiprocs=4:ngpus=4

### Set temp to scratch
[[ "x${TMPDIR}" == "x" ]] && export TMPDIR=${SCRATCH}/tmp && mkdir -p $TMPDIR

. config_env.sh >/dev/null 2>&1 || exit 1

nnodes=$(cat ${PBS_NODEFILE} | sort | uniq | wc -l)
nranks=$(cat ${PBS_NODEFILE} | sort | wc -l)
nranks_per_node=$((${nranks} / ${nnodes}))

status="SUCCESS"

[[ "x${PBS_NODEFILE}" != "x" ]] || { echo "Not in a PBS Job, exiting..."; exit 0; }

export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1

[[ -f ./Example02_CBL.in ]] || wget https://raw.githubusercontent.com/NCAR/FastEddy-tutorials/main/examples/Example02_CBL.in \
    || { echo "Cannot download input file!!"; exit 1; }

mkdir ./output

tstart=$(date +%s)
echo "# --> BEGIN execution"

mpiexec --np ${nranks} --ppn ${nranks_per_node} --no-transfer \
  get_local_rank \
  $(pwd)/fasteddy/${NCAR_BUILD_ENV}/FastEddy \
  ./Example02_CBL.in \
    || status="FAILED"

echo "# --> END execution"

tstop=$(date +%s)
echo $((${tstop}-${tstart})) " elapsed seconds"
echo && echo && echo ${status} $(date)
