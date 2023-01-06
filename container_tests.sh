#!/bin/bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# [ -f ${SCRIPTDIR}/sanitize_env.sh ] && . ${SCRIPTDIR}/sanitize_env.sh || \
#      { echo "cannot locate ${SCRIPTDIR}/sanitize_env.sh}"; exit 1; }
[ -f ${SCRIPTDIR}/config_env.sh ] && . ${SCRIPTDIR}/config_env.sh || \
    { echo "cannot locate ${SCRIPTDIR}/config_env.sh}"; exit 1; }
#----------------------------------------------------------------------------

spack env activate -p container_env


# preliminaries - podman at least seems to require a local filesystem, try leaving TMPDIR on lustre
# and I expect failures...
clean_container_dirs()
{
    chmod -R u+rwX /var/tmp/${USER}*
    rm -rf /var/tmp/${USER}*
    mkdir -p /var/tmp/${USER}
    [ -d ${TMPDIR} ] || mkdir -p ${TMPDIR}
}
clean_container_dirs


[ -f ~/.config/containers/storage.conf ] || cat > ~/.config/containers/storage.conf <<EOF
[storage]
   driver="vfs"
   runroot="/var/tmp/${USER}_podman/images"
   rootless_storage_path="/var/tmp/${USER}_podman/storage"

[storage.options]
  ignore_chown_errors="true"

EOF

# #----------------------------------------------------------------------------
# cd ${SCRIPTDIR}/minimal || exit 1
# label="CharlieCloud minimal -- build"
# message_running ${label}
# ln -sf Dockerfile.ch Dockerfile

# try_command ch-image build --force .
# try_command ch-image list
# try_command ch-convert minimal /var/tmp/${USER}/minimal

# label="CharlieCloud minimal -- run"
# message_running ${label}
# try_command ch-run /var/tmp/${USER}/minimal -- cat /etc/redhat-release
# try_command "ch-run /var/tmp/${USER}/minimal -- rpm -qa | sort | uniq"
# try_command ch-run /var/tmp/${USER}/minimal -- gcc --version


# #----------------------------------------------------------------------------
# cd ${SCRIPTDIR}/minimal || exit 1
# label="Podman minimal -- build"
# message_running ${label}
# ln -sf Dockerfile.podman Dockerfile


# try_command podman build --tag minimal .
# try_command podman images
# try_command podman run minimal cat /etc/redhat-release
# try_command "podman run minimal rpm -qa | sort | uniq"
# try_command podman run minimal gcc --version



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
