# dev-env

Devcontainer definition and provisioning for the local development environment
(ROCm/Ubuntu image, Python venv, and the editable science repos under
`/workspaces/code`).

## Available toolchains

The container ships a full TeX Live 2023 distribution (`latexmk`,
`pdflatex`, `lualatex`, incl. `physics`/`booktabs`) — theory documents can
and should be validated by actual compilation. No flake8/ruff in the venv.

## Running GPAW / MPI locally

GPAW is **pure MPI — one thread per rank**. When launching under `mpirun` on
the local dev box, **always pin the BLAS/OpenMP thread count**, or each rank
spawns ~`nproc` BLAS threads and oversubscribes the machine (observed:
`mpirun -np 4` with unpinned threads → load average ~90 on a 24-core box):

```bash
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
mpirun -np N python script.py     # then -np N uses exactly N cores
```

Keep `-np` modest relative to `nproc`. Cluster SLURM scripts already export
`OMP_NUM_THREADS=1`; this is the local-run analogue, and every local driver
(`run_scan.sh`, `run_phonons.sh`, `sweep.sh`, …) should export it too.
(Recent GPAW also needs `GPAW_MPI_BACKEND=cgpaw` under an MPI launcher with
plain `python`.)

## Git workflow

This is a single-maintainer configuration repo. Commit changes **directly to
`main`** — do not create a topic branch first. Pushing still requires explicit
confirmation from the user.
