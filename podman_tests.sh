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
label="Podman openhpc -- build"
message_running ${label}
ln -sf Dockerfile.podman Dockerfile

try_command podman build --tag openhpc .
try_command podman images

label="Podman openhpc -- run"
message_running ${label}
try_command podman run openhpc cat /etc/os-release /etc/ohpc-release
try_command podman run openhpc bash -c \
             '". /etc/profile.d/lmod.sh && module avail && module list && which mpicxx && mpicxx --version"'

# clean up
clean_container_dirs


exit 0
