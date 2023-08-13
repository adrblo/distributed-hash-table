using MPI
using MPITape


function myAllreduce!(sendrecv, op, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    size = MPI.Comm_size(comm)

    buf2 = similar(sendrecv)

    n = Int64(log2(size))
    for i = n:-1:1
        dest = rank ⊻ (2^i - 1)
        MPI.Isend(sendrecv, comm; dest=dest)
        MPI.Recv!(buf2, comm, source=dest)
        sendrecv .= op(buf2, sendrecv)
    end
end

MPITape.new_overdub(myAllreduce!, (:rank, "all", :(Dict("data" => args[1], "mode" => "CYC"))))

function your_mpi_code()
    rank = MPI.Comm_rank(MPI.COMM_WORLD)


    vec = [1, 2, 3, 4]

    myAllreduce!(vec, +, MPI.COMM_WORLD)
end

MPI.Init()

@record your_mpi_code()

rank = MPI.Comm_rank(MPI.COMM_WORLD)
# delayed printing
sleep(rank)
MPITape.print_mytape()

# save local tapes to disk
MPITape.save()

MPI.Barrier(MPI.COMM_WORLD)
if rank == 0 # on master
    # read all tapes and merge them into one
    tape_merged = MPITape.readall_and_merge()
    # print the merged tape
    println(MPITape.json_merged(tape_merged))
    MPITape.dump_merged(tape_merged, "merged.json")
    # plot the merged tape (beta)
    # display(MPITape.plot_sequence_merged(tape_merged))
    # MPITape.plot_merged(tape_merged)
end

MPI.Finalize()