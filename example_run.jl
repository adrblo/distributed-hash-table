using MPI
using MPITape

@enum Command begin
    noCommand = 0
    otherCommand = 1
end

struct Message
    command::Command
end


function empty_message()
    return Message(noCommand)
end

function send_message(command::Command, dest, comm::MPI.Comm)
    MPI.Isend([Message(command)], comm; dest=dest)
end


function occupied(arr::Array{Message})
    counter = 0
    for elem::Message in arr
        if elem.command !== noCommand
            counter += 1
        end
    end
    return counter
end

#MPITape.new_overdub(myAllreduce!, (:rank, "all", :(Dict("data" => args[1], "mode" => "CYC"))))
MPITape.new_overdub(send_message, (:rank, :(args[2]), :(Dict("command" => args[1]))))

function main()
    start_time = MPI.Wtime()
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(MPI.COMM_WORLD)
    size = MPI.Comm_size(comm)


    recvbuf = [empty_message() for i in 1:size^2]
    sleep_time = 0.1

    if rank == 0
        counter = 0
        while MPI.Wtime() - start_time < 40
            if MPI.Iprobe(comm; source=MPI.ANY_SOURCE)
                test = MPI.Recv(Message, comm; source=MPI.ANY_SOURCE)
                if test.command !== noCommand
                    counter += 1
                end
                println(test)
                println("--loooooop--")
            end
            sleep(sleep_time)
        end
        println("Count: $(counter)")
    else
        send_message(otherCommand, 0, comm)
        sleep(2)
        send_message(otherCommand, 0, comm)

    end

    MPI.Barrier(comm)
end

MPI.Init()

@record main()
#main()

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