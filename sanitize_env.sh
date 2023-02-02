#!/usr/bin/env bash


# type module >/dev/null 2>&1 \
#     && module --force purge \
#     && module unuse ${MODULEPATH} \
#     && unset module LMOD_MODULERCFILE LMOD_SYSTEM_DEFAULT_MODULES MODULEPATH_ROOT MODULESHOME BASH_FUNC_ml \
#              LMOD_CMD LMOD_DIR LMOD_PKG LMOD_ROOT LMOD_SETTARG_FULL_SUPPORT LMOD_SHELL_PRGM LMOD_SYSTEM_NAME \
#              LMOD_VERSION LUAROCKS_PREFIX LUA_CPATH LUA_PATH _ModuleTable001_ _ModuleTable002_ _ModuleTable_Sz_ \
#              __LMOD_STACK_LMOD_SYSTEM_DEFAULT_MODULES __LMOD_REF_COUNT_CMAKE_PREFIX_PATH __LMOD_REF_COUNT_PKG_CONFIG_PATH \
#              __Init_Default_Modules __LMOD_REF_COUNT_MANPATH __LMOD_REF_COUNT_PATH \
#     && env | egrep -i "LMOD|MODU" | sort \
#     && echo "removed builtin module environment" \
#     && echo "PATH=$PATH" \
#     && echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
