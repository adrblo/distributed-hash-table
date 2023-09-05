using MPI
using MPITape

include("mpi_operations.jl")
include("operations.jl")

function empty_message(rank)
    return Message(noCommand; from=rank)
end

function send_message(command::Command, rank, dest, comm::MPI.Comm)
    MPI.Isend(Message(command; from=rank), comm; dest=dest)
end

struct Event
    start::Int
    ranks::Vector{Int}
    func::Function
end

function setup_events(rank, comm, ←)
    # Events: (time in sec., ranks, function)
    events = [
        Event(1, [1, 2], () -> (3 ← info(1))),
        Event(2, [1, 2], () -> (2 ← info(1))),
        Event(3, [3], () -> (2 ← linearize(3))),
    ]
    
    rank_events = []

    for event in events
        if rank in event.ranks
            push!(rank_events, event)
        end
    end

    return sort(rank_events, by=e -> e.start), zeros(Bool, size(rank_events, 1))
end

function check_and_do_events!(events, done_events, time)
    for (index, (event::Event, done)) in enumerate(zip(events, done_events))
        if !done && event.start <= time
            event.func()
            done_events[index] = true
        elseif event.start > time
            # may break, because events are sorted and assuming increasing time
            break
        end
    end
end

#MPITape.new_overdub(myAllreduce!, (:rank, "all", :(Dict("data" => args[1], "mode" => "CYC"))))
MPITape.new_overdub(send_message, (:rank, :(args[2]), :(Dict("command" => args[1]))))
MPITape.new_overdub(∇, (:rank, :(args[2]), :(Dict("command" => args[1].command))))
MPITape.new_overdub(∘, (:rank, :rank, :(Dict("command" => args[2].command))))
#MPITape.overdub_mpi()

function example_run()
    sleep_time = 0.0001 # checkup and refresh delay
    max_time = 15 # maximum time of run

    start_time = MPI.Wtime()
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(MPI.COMM_WORLD)
    size = MPI.Comm_size(comm)

    handle_message, ← = build_handle_message(rank, comm)

    events, done_events = setup_events(rank, comm, ←)

    while MPI.Wtime() - start_time < max_time
        if MPI.Iprobe(comm; source=MPI.ANY_SOURCE)
            message = MPI.Recv(Message, comm; source=MPI.ANY_SOURCE)
            if message.command !== noCommand
                handle_message(message)
            end
        end

        # do events
        check_and_do_events!(events, done_events, MPI.Wtime() - start_time)

        # apply refresh speed
        sleep(sleep_time)
    end

    MPI.Barrier(comm)
end

MPI.Init()

@record example_run()
#example_run

rank = MPI.Comm_rank(MPI.COMM_WORLD)
# delayed printing
sleep(rank)
#MPITape.print_mytape()

# save local tapes to disk
MPITape.save()

MPI.Barrier(MPI.COMM_WORLD)
if rank == 0 # on master
    # read all tapes and merge them into one
    tape_merged = MPITape.readall_and_merge()
    # print the merged tape
    MPITape.print_merged(tape_merged)
    MPITape.dump_merged(tape_merged, "merged.json")
    # plot the merged tape (beta)
    # display(MPITape.plot_sequence_merged(tape_merged))
    # MPITape.plot_merged(tape_merged)
end

MPI.Finalize()