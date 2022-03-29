#!/bin/bash

# Set a compiler to test with, e.g. '%gcc', '%clang', etc.
compiler=''
cuda_arch="70"

mfem='mfem@4.4.0'${compiler}
mfem_dev='mfem@develop'${compiler}

backends='+occa+raja+libceed'
backends_specs='^occa~cuda ^raja~openmp'

# help the concrtizer find suitable hdf5 version (conduit constraint)
hdf5_spec='^hdf5@1.8.19:1.8'
# petsc spec (petsc versions @3.14.0:3.16.5 cause failures in petsc ex5/ex11p)
petsc_spec='^petsc@3.13.6+suite-sparse+mumps'
# strumpack spec without cuda
strumpack_spec='^strumpack~slate~openmp~cuda'
strumpack_cuda_spec='^strumpack~slate~openmp'

builds=(
    # preferred version:
    ${mfem}
    ${mfem}'~mpi~metis~zlib'
    ${mfem}"$backends"'+superlu-dist+strumpack+suite-sparse+petsc+slepc \
        +sundials+pumi+gslib+mpfr+netcdf+zlib+gnutls+libunwind+conduit \
        '"$backends_specs $petsc_spec $strumpack_spec $hdf5_spec"
    ${mfem}'~mpi \
        '"$backends"'+suite-sparse+sundials+gslib+mpfr+netcdf \
        +zlib+gnutls+libunwind+conduit \
        '"$backends_specs $hdf5_spec"' ^sundials~mpi'

    # develop version:
    ${mfem_dev}'+shared~static'
    ${mfem_dev}'+shared~static~mpi~metis~zlib'
    # NOTE: Shared build with +gslib works on mac but not on linux
    ${mfem_dev}'+shared~static \
        '"$backends"'+superlu-dist+strumpack+suite-sparse+petsc+slepc \
        +sundials+pumi+gslib+mpfr+netcdf+zlib+gnutls+libunwind+conduit \
        '"$backends_specs $petsc_spec $strumpack_spec $hdf5_spec"
    ${mfem_dev}'+shared~static~mpi \
        '"$backends"'+suite-sparse+sundials+gslib+mpfr+netcdf \
        +zlib+gnutls+libunwind+conduit \
        '"$backends_specs $hdf5_spec"' ^sundials~mpi'
)

builds2=(
    # preferred version
    ${mfem}"$backends $backends_specs"
    ${mfem}'+superlu-dist'
    ${mfem}'+strumpack'" $strumpack_spec"
    ${mfem}'+suite-sparse~mpi'
    ${mfem}'+suite-sparse'
    ${mfem}'+sundials~mpi ^sundials~mpi'
    ${mfem}'+sundials'
    ${mfem}'+pumi'
    ${mfem}'+gslib'
    ${mfem}'+netcdf~mpi'
    ${mfem}'+netcdf'
    ${mfem}'+mpfr'
    ${mfem}'+gnutls'
    ${mfem}'+conduit~mpi'
    ${mfem}'+conduit'
    ${mfem}'+umpire'
    ${mfem}'+petsc'" $petsc_spec"
    ${mfem}'+petsc+slepc'" $petsc_spec"
    ${mfem}'+threadsafe'
    # develop version
    ${mfem_dev}"$backends $backends_specs"
    ${mfem_dev}'+superlu-dist'
    ${mfem_dev}'+strumpack'" $strumpack_spec"
    ${mfem_dev}'+suite-sparse~mpi'
    ${mfem_dev}'+suite-sparse'
    ${mfem_dev}'+sundials~mpi ^sundials~mpi'
    ${mfem_dev}'+sundials'
    ${mfem_dev}'+pumi'
    ${mfem_dev}'+gslib'
    ${mfem_dev}'+netcdf~mpi'
    ${mfem_dev}'+netcdf'
    ${mfem_dev}'+mpfr'
    ${mfem_dev}'+gnutls'
    ${mfem_dev}'+conduit~mpi'
    ${mfem_dev}'+conduit'
    ${mfem_dev}'+umpire'
    ${mfem_dev}'+petsc'" $petsc_spec"
    ${mfem_dev}'+petsc+slepc'" $petsc_spec"
    ${mfem_dev}'+threadsafe'
)

builds_cuda=(
    ${mfem}'+cuda cuda_arch='"${cuda_arch}"

    ${mfem}'+cuda+raja+occa+libceed cuda_arch='"${cuda_arch}"' \
        ^raja+cuda~openmp'

    ${mfem}'+cuda+openmp+raja+occa+libceed cuda_arch='"${cuda_arch}"' \
        +superlu-dist+strumpack+suite-sparse+petsc+slepc \
        +sundials+pumi+gslib+mpfr+netcdf+zlib+gnutls+libunwind+conduit \
        ^raja+cuda+openmp'" $strumpack_cuda_spec $petsc_spec $hdf5_spec"

    # same builds as above with ${mfem_dev}
    ${mfem_dev}'+cuda cuda_arch='"${cuda_arch}"

    ${mfem_dev}'+cuda+raja+occa+libceed cuda_arch='"${cuda_arch}"' \
        ^raja+cuda~openmp'

    # add '^sundials+hypre' to help the concretizer
    ${mfem_dev}'+cuda+openmp+raja+occa+libceed cuda_arch='"${cuda_arch}"' \
        +superlu-dist+strumpack+suite-sparse+petsc+slepc \
        +sundials+pumi+gslib+mpfr+netcdf+zlib+gnutls+libunwind+conduit \
        ^raja+cuda+openmp'" $strumpack_cuda_spec $petsc_spec"' \
        ^sundials+hypre'" $hdf5_spec"
)


trap 'printf "\nScript interrupted.\n"; exit 33' INT

SEP='=========================================================================='
sep='--------------------------------------------------------------------------'

run_builds=("${builds[@]}" "${builds2[@]}")
# run_builds=("${builds_cuda[@]}")

for bld in "${run_builds[@]}"; do
    printf "\n%s\n" "${SEP}"
    printf "    %s\n" "${bld}"
    printf "%s\n" "${SEP}"
    eval bbb="\"${bld}\""
    spack spec -I $bbb || exit 1
    printf "%s\n" "${sep}"
    spack install --test=root $bbb || exit 2
done

# Uninstall all mfem builds:
# spack uninstall --all mfem
