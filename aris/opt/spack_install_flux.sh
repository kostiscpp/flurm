#!/bin/bash

module load gnu/8
module load gnu/13.2.0
module load python/3.9.18
module load git
module load zlib
module load rust

export SPACK_PYTHON="$(dirname "$(dirname "$(which python)")")"
git clone --depth=2 --branch releases/v1.0 https://github.com/spack/spack.git
#export SPACK_USER_CACHE_PATH=/path/to/.spack #default is ~/.spack
#export SPACK_USER_CONFIG_PATH=/path/to/.spack #default is ~/.spack
. spack/share/spack/setup-env.sh

spack config add config:verify_ssl:false 
# Find external compilers, libraries and the python interpreter
spack compiler add /apps/compilers/gnu/13.2.0
spack external find rust
spack external find python
spack external find zlib
# We do not need to build rust in spack
spack config add packages:rust:buildable:false
# Flags and external library paths that spack misses by default
sed -i '283i             current_environment["LDFLAGS"] = "-lrt"\n            current_environment["PYO3_USE_ABI3_FORWARD_COMPATIBILITY"] = "1"\n             existing = current_environment.get("LD_LIBRARY_PATH", "")            current_environment["LD_LIBRARY_PATH"] = f"/apps/libraries/zlib/1.2.11/lib:/apps/compilers/gnu/13.2.0/lib:/apps/compilers/gnu/13.2.0/lib64:/apps/applications/python/3.9.18/lib:{existing}"' spack/lib/spack/spack/util/executable.py
# Finally install flux
spack install --yes-to-all flux-sched

