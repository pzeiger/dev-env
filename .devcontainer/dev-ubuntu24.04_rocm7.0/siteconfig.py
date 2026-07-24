import os
from pathlib import Path

mpi = True
if mpi:
    compiler = 'mpicc'

if '-fopenmp' not in extra_compile_args:
    extra_compile_args += ['-fopenmp']

if '-fopenmp' not in extra_link_args:
    extra_link_args += ['-fopenmp']

print(extra_compile_args)
print(extra_link_args)

build_flags = '{build_flags_c}'

for x in build_flags.strip(' ').split('-')[1:]:
    flag = '-' + x.strip()
    extra_compile_args += [flag]
    extra_link_args += [flag]

my_includes = [
    os.getenv('OPENBLAS_INCLUDE', ''),
    os.getenv('SCALAPACK_INCLUDE', ''),
    os.getenv('LIBXC_INCLUDE', ''),
    os.getenv('LIBVDWXC_INCLUDE', ''),
    os.getenv('FFTW_INCLUDE', ''),
]

my_libs = [
    os.getenv('OPENBLAS_LIBS', ''),
    os.getenv('SCALAPACK_LIBS', ''),
    os.getenv('LIBXC_LIBS', ''),
    os.getenv('LIBVDWXC_LIBS', ''),
    os.getenv('FFTW_LIBS', ''),
]

for minc in my_includes:
    if minc not in include_dirs and minc != '':
        include_dirs += [minc]

for mlib in my_libs:
    if mlib not in library_dirs and mlib != '':
        library_dirs += [mlib]

    if mlib not in runtime_library_dirs and mlib != '':
        runtime_library_dirs += [mlib]

###################
# SCALAPACK
###################
if 'scalapack' not in libraries or 'scalapack-openmpi' not in libraries:
    tmpdir = Path('/usr/lib/x86_64-linux-gnu')
    scalapack = True
    blacs = True
    if (tmpdir / 'libscalapack-openmpi.so').exists():
        libraries += ['scalapack-openmpi']
    elif (tmpdir / 'libscalapack.so').exists():
        libraries += ['scalapack']

if 'openblas' not in libraries:
    libraries += ['openblas']

if 1:
    libxc = True
    if 'xc' not in libraries:
        libraries += ['xc']


if 1:
    libvdwxc = True
    if 'vdwxc' not in libraries:
        libraries += ['vdwxc']


###################
# FFTW3
###################
if 1:
    tmpdir = Path('/lib/x86_64-linux-gnu')
    fftw = True

    # Prefer OMP threaded version
    if 'fftw3_omp' not in libraries:
        if (tmpdir / 'libfftw3_omp.so').exists():
            libraries += ['fftw3_omp']
    elif 'fftw3' not in libraries:
        if (tmpdir / 'libfftw3.so').exists():
            libraries += ['fftw3']

    if 'fftw3_mpi' not in libraries:
        if (tmpdir / 'libfftw3_mpi.so').exists():
            libraries += ['fftw3_mpi']


# hip
if os.getenv('GPAW_BUILD_GPU', '0') == '1':
    gpu = True
    gpu_target = 'hip-amd'
    gpu_compiler = 'hipcc'
    gpu_include_dirs = ['/opt/rocm/include']
    gpu_library_dirs = ['/opt/rocm/lib']
    # This box is a Strix Halo iGPU whose native arch is gfx1151, and ROCm 7.2
    # supports it natively (the Dockerfile no longer sets
    # HSA_OVERRIDE_GFX_VERSION). HIP kernels must be compiled for the arch the
    # runtime reports or launches segfault, so default to gfx1151. If the
    # override is reinstated (runtime then reports gfx1100), set
    # GPAW_GPU_ARCH=gfx1100 to match.
    gpu_arch = os.getenv('GPAW_GPU_ARCH', 'gfx1151')
    gpu_compile_args = [
        '-g',
        '-O3',
        f'--offload-arch={gpu_arch}',
       ]
    libraries += ['amdhip64', 'hipblas']
    # The host C compiler (mpicc) also pulls in <hip/hip_runtime.h> from the
    # GPU-enabled C sources (e.g. c/bc.c via gpu-runtime.h) and links the HIP
    # runtime, so the rocm include/lib dirs must be on the *general* paths too,
    # not only gpu_include_dirs/gpu_library_dirs (which apply to hipcc only).
    if '/opt/rocm/include' not in include_dirs:
        include_dirs += ['/opt/rocm/include']
    if '/opt/rocm/lib' not in library_dirs:
        library_dirs += ['/opt/rocm/lib']
    if '/opt/rocm/lib' not in runtime_library_dirs:
        runtime_library_dirs += ['/opt/rocm/lib']


#if 'blacs' not in libraries:
#    libraries += ['blacs']


