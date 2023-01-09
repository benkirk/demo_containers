#!/bin/bash

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

spack env activate -p container_env


# preliminaries - podman at least seems to require a local filesystem, try leaving TMPDIR on lustre
# and I see failures...
clean_container_dirs()
{
    chmod -R u+rwX /var/tmp/${USER}*
    rm -rf /var/tmp/${USER}*
    mkdir -p /var/tmp/${USER}
    [ -d ${TMPDIR} ] || mkdir -p ${TMPDIR}
}
clean_container_dirs


[ -f ~/.config/containers/storage.conf ] \
    || mkdir -p ~/.config/containers/ && cat > ~/.config/containers/storage.conf <<EOF
[storage]
   driver="vfs"
   runroot="/var/tmp/${USER}_podman/images"
   rootless_storage_path="/var/tmp/${USER}_podman/storage"

[storage.options]
  ignore_chown_errors="true"

EOF

#----------------------------------------------------------------------------
cd ${SCRIPTDIR}/minimal || exit 1
label="Charliecloud minimal -- build"
message_running ${label}
ln -sf Dockerfile.ch Dockerfile

try_command ch-image build --force .
try_command ch-image list
try_command ch-convert minimal /var/tmp/${USER}/minimal

label="Charliecloud minimal -- run"
message_running ${label}
try_command ch-run /var/tmp/${USER}/minimal -- cat /etc/redhat-release
try_command "ch-run /var/tmp/${USER}/minimal -- rpm -qa | sort | uniq"
try_command ch-run /var/tmp/${USER}/minimal -- gcc --version

# Charliecloud internal SquashFUSE support - requires https://github.com/spack/spack/pull/34847
label="Charliecloud minimal -- SquashFUSE"
message_running ${label}
try_command ch-convert minimal ./minimal.sqfs
try_command ch-run ./minimal.sqfs -- cat /etc/redhat-release
try_command ch-run ./minimal.sqfs -- gcc --version

# optionally, additional (expensive) Charliecloud tests:
[[ true == ${full_tests} ]] && ${SCRIPTDIR}/charliecloud_tests.sh



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
[[ true == ${full_tests} ]] && ${SCRIPTDIR}/podman_tests.sh



#----------------------------------------------------------------------------
cd ${SCRIPTDIR}/singularity || exit 1
rm -f ./*.sif
label="Singularity"
message_running ${label}

try_command singularity pull opensuse15-spack-prereqs.sif docker://benjaminkirk/opensuse15-spack-prereqs:0.0.1
try_command singularity pull opensuse15-openhpc.sif docker://benjaminkirk/opensuse15-openhpc:0.0.1
try_command singularity pull rocky9-libmesh-prereqs.sif docker://benjaminkirk/rocky9-libmesh-prereqs:0.0.1

try_command singularity exec --cleanenv opensuse15-openhpc.sif bash -c \
            '". /etc/profile.d/lmod.sh && module avail && module list && which mpicxx"'

try_command singularity exec rocky9-libmesh-prereqs.sif cat /etc/redhat-release
try_command singularity exec rocky9-libmesh-prereqs.sif gcc --version

# clean up
clean_container_dirs


exit 0
