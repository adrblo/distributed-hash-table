using MPI
using MPITape

struct Particle
    x::Float32
    y::Float32
    z::Float32
    message::Int32
    rank::Int32
    velocity::Float32
    mass::Float64
end

function Particle(message, rank)
    return Particle(
        rand(Float32),
        rand(Float32),
        rand(Float32),
        message,
        rank,
        rand(Float32),
        rand(),
    )
end

function send_particle(dest, message, from, comm::MPI.Comm)
    MPI.Isend(Particle(message, from), comm; dest=dest)
end


function myAllreduce!(sendrecv, op, comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    

    buf2 = similar(sendrecv)

    n = Int64(log2(size))
    for i = n:-1:1
        dest = rank ⊻ (2^i - 1)
        MPI.Isend(sendrecv, comm; dest=dest)
        MPI.Recv!(buf2, comm, source=dest)
        sendrecv .= op(buf2, sendrecv)
    end
end


function occupied(arr)
    counter = 0
    for elem in arr
        if elem !== nothing
            counter += 1
        end
    end
    return counter
end

#MPITape.new_overdub(myAllreduce!, (:rank, "all", :(Dict("data" => args[1], "mode" => "CYC"))))
MPITape.new_overdub(send_particle, (:rank, :(args[1]), :(Dict("data" => "123", "mode" => "CYC"))))

function main()
    start_time = MPI.Wtime()
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(MPI.COMM_WORLD)
    size = MPI.Comm_size(comm)


    recvbuf = Array{Union{Nothing, Particle}}(nothing, 100)
    counter = 0
    sleep_time = 1

    if rank == 0
        while MPI.Wtime() - start_time < 10
            MPI.Irecv!(recvbuf, MPI.COMM_WORLD; source=MPI.ANY_SOURCE)
            counter += occupied(recvbuf)
            empty!(recvbuf)
            sleep(sleep_time)
        end
        print("Count: $(counter)")
    else
        sleep(2)
        send_particle(0, 1, rank, comm)
    end

    MPI.Barrier(comm)
end

MPI.Init()

# @record main()
main()

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