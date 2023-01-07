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


#----------------------------------------------------------------------------
cd ${SCRIPTDIR}/openhpc || exit 1
label="CharlieCloud openhpc -- build"
message_running ${label}
ln -sf Dockerfile.ch Dockerfile

try_command ch-image build --force .
try_command ch-image list
try_command ch-convert openhpc /var/tmp/${USER}/openhpc
try_command ch-convert openhpc ./openhpc.sqfs

label="Charliecloud openhpc -- directory image"
message_running ${label}
try_command ch-run /var/tmp/${USER}/openhpc -- cat /etc/os-release /etc/ohpc-release
try_command "ch-run /var/tmp/${USER}/openhpc -- rpm -qa | sort | uniq"
try_command ch-run /var/tmp/${USER}/openhpc -- gcc --version

# Charliecloud internal SquashFUSE support - requires https://github.com/spack/spack/pull/34847
label="Charliecloud openhpc -- SquashFUSE image"
message_running ${label}
try_command ch-run ./openhpc.sqfs -- cat /etc/os-release /etc/ohpc-release
try_command ch-run ./openhpc.sqfs -- gcc --version
try_command ch-run ./openhpc.sqfs -- bash -lc \
            '". /etc/profile.d/lmod.sh && module avail && module list && which mpicxx && mpicxx --version"'

cd ${SCRIPTDIR}/rockylinux || exit 1
label="Charliecloud pull, convert (SquashFUSE), & run rocky8 image"
message_running ${label}
try_command ch-image pull benjaminkirk/rocky8-libmesh-prereqs:0.0.1
try_command ch-image list
rm -f ./rocky8-libmesh-prereqs.sqfs
try_command ch-convert benjaminkirk/rocky8-libmesh-prereqs:0.0.1 ./rocky8-libmesh-prereqs.sqfs
try_command ch-run ./rocky8-libmesh-prereqs.sqfs -- gcc --version
try_command ch-run ./rocky8-libmesh-prereqs.sqfs -- bash -lc \
            '"module use /usr/share/modulefiles && module avail && module load mpi && module list && which mpicxx && mpicxx --version"'

label="Charliecloud pull, convert (SquashFUSE), & run rocky9 image"
message_running ${label}
try_command ch-image pull benjaminkirk/rocky9-libmesh-prereqs:0.0.1
try_command ch-image list
rm -f ./rocky9-libmesh-prereqs.sqfs
try_command ch-convert benjaminkirk/rocky9-libmesh-prereqs:0.0.1 ./rocky9-libmesh-prereqs.sqfs
try_command ch-run ./rocky9-libmesh-prereqs.sqfs -- gcc --version
try_command ch-run ./rocky9-libmesh-prereqs.sqfs -- bash -lc \
            '"module use /usr/share/modulefiles && module avail && module load mpi && module list && which mpicxx && mpicxx --version"'

# clean up
clean_container_dirs


exit 0
