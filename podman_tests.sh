#!/bin/bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

[ -f ${SCRIPTDIR}/sanitize_env.sh ] && . ${SCRIPTDIR}/sanitize_env.sh

[ -f ${SCRIPTDIR}/config_env.sh ] && . ${SCRIPTDIR}/config_env.sh || \
    { echo "cannot locate ${SCRIPTDIR}/config_env.sh"; exit 1; }
#----------------------------------------------------------------------------

spack env activate -p container_env

clean_container_dirs

# process any command line args:
full_tests=false
build_tests=true
pull_tests=true

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
        *)
            ;;
    esac
    shift
done


#----------------------------------------------------------------------------
if [[ true == ${build_tests} ]]; then
    clean_container_dirs
    cd ${SCRIPTDIR}/openhpc || exit 1
    label="Podman openhpc -- build"
    message_running ${label}
    ln -sf Dockerfile.podman Dockerfile

    try_command podman build --tag openhpc .
    try_command podman images

    label="Podman openhpc -- run"
    message_running ${label}
    try_command podman run openhpc cat /etc/os-release /etc/ohpc-release
    try_command podman run openhpc bash -lc \
                '". /etc/profile.d/lmod.sh && module avail && module list && which mpicxx && mpicxx --version"'
    clean_container_dirs
fi

if [[ true == ${pull_tests} ]]; then
    cd ${SCRIPTDIR}/rockylinux || exit 1
    # label="Podman pull & run rocky8 image"
    # message_running ${label}
    # try_command podman image pull docker://benjaminkirk/rocky8-libmesh-prereqs:0.0.1
    # try_command podman images
    # # should work but doesn't yet:
    # try_command podman run rocky8-libmesh-prereqs:0.0.1 gcc --version
    # # should work but doesn't yet:
    # try_command podman run rocky8-libmesh-prereqs:0.0.1 bash -lc \
    #             '"module use /usr/share/modulefiles && module avail && module load mpi && module list && which mpicxx && mpicxx --version"'

    label="Podman pull & run rocky9 image"
    message_running ${label}
    try_command podman image pull docker://benjaminkirk/rocky9-libmesh:0.0.1
    try_command podman images
    # should work but doesn't yet:
    try_command podman run rocky9-libmesh:0.0.1 gcc --version
    # should work but doesn't yet:
    try_command podman run rocky9-libmesh:0.0.1 bash -lc \
                '"module use /usr/share/modulefiles && module avail && module load mpi && module list && which mpicxx && mpicxx --version"'
    label+=" (MPI Inside container)"
    message_running ${label}
    # should work but doesn't yet:
    try_command podman run rocky9-libmesh:0.0.1 bash -lc \
                '"module use /usr/share/modulefiles && module avail && module load mpi && module list && cd /tmp && touch foo && mpiexec -n 4 /opt/local/libmesh/1.8.0-pre-mpich-x86_64/examples/introduction/ex4/example-opt -d 3 -n 25"'
    rm -f ./rocky9-libmesh.sqfs
    clean_container_dirs
fi


# clean up
clean_container_dirs


exit 0
