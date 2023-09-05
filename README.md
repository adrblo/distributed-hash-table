#  Development Repository for Implementing a Distributed Hash Table in Julia MPI

## Setup

Enter Packagemode in Julia REPL and add MPITape Fork

```
] add https://github.com/adrblo/MPITape.jl.git#custom-overdub
] add MPI
```

### Install MPIExcecJL

Open a Julia REPL and enter:

```
using MPI
MPI.install_mpiexecjl()
```

## Running

```
mpiexecjl -n 4 julia --project example_run.jl 
```

