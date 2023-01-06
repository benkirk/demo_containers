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
try_command ch-run ./openhpc.sqfs --  bash -c \
            '". /etc/profile.d/lmod.sh && module avail && module list && which mpicxx"'

# clean up
clean_container_dirs


exit 0
