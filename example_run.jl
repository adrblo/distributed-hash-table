using MPI
using Logging, LoggingExtras

include("function_neighborhood.jl")
include("methods.jl")
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

function setup_events(self, comm, ←)
    # Events: (time in sec., ranks, function)
    events = [
        Event(0, [25], () -> (self ← insert(100, self))),
        Event(4, [17], () -> (self ← search(g(100), self))),
        Event(4, [13], () -> (self ← lookup(g(101), self))),
        Event(6, [54], () -> (self ← delete(g(100), self))),
    ]
    
    rank_events = []

    for event in events
        if self in event.ranks
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


function example_run()
    sleep_time = 0.0001 # checkup and refresh delay
    max_time = 15 # maximum time of run

    start_time = MPI.Wtime()
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(MPI.COMM_WORLD)
    size = MPI.Comm_size(comm)

    logger = SimpleLogger(open("rank_" * string(rank) * ".log", "w+"))
    global_logger(logger)

    p = Process(rank, size)
    @info "Process" p
    handle_message, ← = build_handle_message(rank, comm, p)

    events, done_events = setup_events(rank, comm, ←)

    while MPI.Wtime() - start_time < max_time
        if MPI.Iprobe(comm; source=MPI.ANY_SOURCE)
            message = MPI.Recv(Message, comm; source=MPI.ANY_SOURCE)
            if message.command !== noCommand
                @info "Message: Incoming" message
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

example_run()


MPI.Barrier(MPI.COMM_WORLD)


MPI.Finalize()