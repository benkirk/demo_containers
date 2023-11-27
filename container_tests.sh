#!/bin/bash

origARGS=$@
# process any command line args:
full_tests=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--full-tests)
            full_tests=true
            ;;
        *)
            ;;
    esac
    shift
done

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/config_env.sh ] && . ${SCRIPTDIR}/config_env.sh || \
    { echo "cannot locate ${SCRIPTDIR}/config_env.sh}"; exit 1; }
#----------------------------------------------------------------------------

#spack env activate -p container_env


# preliminaries - podman at least seems to require a local filesystem, try leaving TMPDIR on lustre
# and I see failures...
clean_container_dirs()
{
    chmod -R u+rwX ${CONTAINER_TMP_PREFIX}/${USER}*
    rm -rf ${CONTAINER_TMP_PREFIX}/${USER}*
    mkdir -p ${CONTAINER_TMP_PREFIX}/${USER}
    [ -d ${TMPDIR} ] || mkdir -p ${TMPDIR}
}
clean_container_dirs


[ -f ~/.config/containers/storage.conf ] \
    || mkdir -p ~/.config/containers/ && cat > ~/.config/containers/storage.conf <<EOF
[storage]
   driver="vfs"
   runroot="${CONTAINER_TMP_PREFIX}/${USER}_podman/images"
   rootless_storage_path="${CONTAINER_TMP_PREFIX}/${USER}_podman/storage"

[storage.options]
  ignore_chown_errors="true"

EOF

#----------------------------------------------------------------------------
cd ${SCRIPTDIR}/minimal || exit 1
label="Charliecloud minimal -- build"
message_running ${label}
ln -sf Dockerfile.ch Dockerfile

try_command ch-image build --force fakeroot .
try_command ch-image list
try_command ch-convert minimal ${CONTAINER_TMP_PREFIX}/${USER}/minimal

label="Charliecloud minimal -- run"
message_running ${label}
try_command ch-run ${CONTAINER_TMP_PREFIX}/${USER}/minimal -- cat /etc/redhat-release
try_command "ch-run ${CONTAINER_TMP_PREFIX}/${USER}/minimal -- rpm -qa | sort | uniq"
try_command ch-run ${CONTAINER_TMP_PREFIX}/${USER}/minimal -- gcc --version

# Charliecloud internal SquashFUSE support - requires https://github.com/spack/spack/pull/34847
label="Charliecloud minimal -- SquashFUSE"
message_running ${label}
try_command ch-convert minimal ./minimal.sqfs
try_command ch-run ./minimal.sqfs -- cat /etc/redhat-release
try_command ch-run ./minimal.sqfs -- gcc --version

# optionally, additional (expensive) Charliecloud tests:
[[ true == ${full_tests} ]] && ${SCRIPTDIR}/charliecloud_tests.sh ${origARGS}



#----------------------------------------------------------------------------
cd ${SCRIPTDIR}/minimal || exit 1
label="Podman minimal -- build"
message_running ${label}
ln -sf Dockerfile.podman Dockerfile

try_command podman build --tag minimal .
try_command podman images
try_command podman run minimal cat /etc/redhat-release
try_command "podman run minimal rpm -qa | sort | uniq"
try_command podman run minimal gcc --version

label="Podman minimal -- save / rm / load"
message_running ${label}
rm -f ./minimal.tar
try_command "podman save -o minimal.tar minimal && ls -lh minimal.tar"
try_command podman rm --all # remove all containers first...
try_command podman image rm --all # so we can remove all images next...
try_command podman images # should have nothing...
try_command podman load -i ./minimal.tar # now, load the image we saved and make sure it works
try_command podman images
try_command podman run minimal cat /etc/redhat-release
try_command podman run minimal gcc --version

# optionally, additional (expensive) podman tests:
[[ true == ${full_tests} ]] && ${SCRIPTDIR}/podman_tests.sh ${origARGS}



#----------------------------------------------------------------------------
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

# clean up
clean_container_dirs


exit 0
