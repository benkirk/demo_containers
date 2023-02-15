#!/bin/bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

[ -f ${SCRIPTDIR}/sanitize_env.sh ] && . ${SCRIPTDIR}/sanitize_env.sh

[ -f ${SCRIPTDIR}/config_env.sh ] && . ${SCRIPTDIR}/config_env.sh || \
    { echo "cannot locate ${SCRIPTDIR}/config_env.sh"; exit 1; }
#----------------------------------------------------------------------------

# spack env activate -p container_env

clean_container_dirs

# process any command line args:
full_tests=false
build_tests=true
pull_tests=true
mpi_tests=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--full-tests)
            full_tests=true
            ;;
        --build-tests)
            build_tests=true
            ;;
        --no-build-tests|--skip-build)
            build_tests=false
            ;;
        --pull-tests)
            pull_tests=true
            ;;
        --no-pull-tests|--skip-pull)
            pull_tests=false
            ;;
        --mpi-tests)
            mpi_tests=true
            ;;
        --no-mpi-tests|--skip-mpi)
            mpi_tests=false
            ;;
        *)
            ;;
    esac
    shift
done


#----------------------------------------------------------------------------
if [[ true == ${pull_tests} ]]; then
    cd ${SCRIPTDIR}/singularity || exit 1
    rm -f ./*.sif
    label="Singularity"
    message_running ${label}

    try_command singularity pull opensuse15-spack-prereqs.sif docker://benjaminkirk/opensuse15-spack-prereqs:0.0.1
    try_command singularity pull opensuse15-openhpc.sif docker://benjaminkirk/opensuse15-openhpc:0.0.1
    try_command singularity pull rocky9-libmesh.sif docker://benjaminkirk/rocky9-libmesh:0.0.1

    try_command singularity exec --cleanenv opensuse15-openhpc.sif bash -lc \
                '"module avail && module list && which mpicxx && mpicxx --version"'

    try_command singularity exec rocky9-libmesh.sif cat /etc/redhat-release
    try_command singularity exec rocky9-libmesh.sif gcc --version
    try_command singularity exec rocky9-libmesh.sif bash -lc \
                '"module use /usr/share/modulefiles && module avail && module load mpi && module list && which mpicxx && mpicxx --version"'
    label+=" (MPI Inside container)"
    message_running ${label}
    try_command singularity exec --cleanenv rocky9-libmesh.sif bash -lc \
                '"module use /usr/share/modulefiles && module avail && module load mpi && module list && cd /tmp && touch foo && mpiexec -n 4 /opt/local/libmesh/1.8.0-pre-mpich-x86_64/examples/introduction/ex4/example-opt -d 3 -n 25"'
fi
if [[ true == ${mpi_tests} ]]; then
    cd ${SCRIPTDIR}/singularity || exit 1
    rm -f ./*.sif
    label="Singularity"
    label+=" (MPI Outside container)"
    message_running ${label}
    try_command singularity pull rocky9-libmesh.sif docker://benjaminkirk/rocky9-libmesh:0.0.1
    try_command mpiexec singularity exec --cleanenv rocky9-libmesh.sif bash -lc \
                '"/opt/local/libmesh/1.8.0-pre-mpich-x86_64/examples/introduction/ex4/example-opt -d 3 -n 25"'
fi




# clean up
clean_container_dirs


exit 0
