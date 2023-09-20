using MPI
using Logging, LoggingExtras

include("backend.jl")
include("process.jl")
include("skip_plus.jl")
include("hash_table.jl")
include("operations.jl")

function setup_events(self, comm, ←, p, number_ranks)
    # Events: (time in sec., ranks, function)
    events = [
        # Case 1: insert to end of chain and add node to begin of list
        Event(0, [30], () -> (self ← insert(67, self))),
        Event(0, [4], () -> (29 ← insert(120, self))),
        Event(0, [0], () -> (29 ← insert(120, self))),
        Event(5, [14], () -> (31 ← join(self))),
        # Case 1a: search, lookup and delete value from case 1
        Event(20, [4], () -> (29 ← search(g(120), self))),
        Event(20, [4], () -> (29 ← lookup(g(120), self))),
        Event(25, [4], () -> (29 ← delete(g(120), self))),
        # Case 2: add values and search them
        Event(10, [3], () -> (self ← insert(10, self))),
        Event(15, [3], () -> (self ← search(g(10), self))),
        Event(15, [3], () -> (self ← lookup(g(10), self)))
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
    sleep_time = 0.001 # checkup and refresh delay
    max_time = 60 # maximum time of run
    we_do_timeout = true
    unconnected_nodes = [14]

    start_time = MPI.Wtime()
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(MPI.COMM_WORLD)
    size = MPI.Comm_size(comm)

    logger = SimpleLogger(open("rank_" * string(rank) * ".log", "w+"))
    global_logger(logger)

    if rank in unconnected_nodes
        p = EmptyProcess(rank)
    else
        p = Process(rank, setdiff(range(0, size-1), unconnected_nodes))
    end
    @info "Process" p.self p.left p.right p.circ p.neighbors p.storage h(p.self) bitstring(id(p.self))
    handle_message, ← = build_handle_message(rank, comm, p)

    events, done_events = setup_events(rank, comm, ←, p, size)

    loop_counter = 1
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

        if loop_counter % 5000 == 0 && we_do_timeout && MPI.Wtime() - start_time < (max_time - 10)
            timeout(p, ←)
        end

        # apply refresh speed
        sleep(sleep_time)

        loop_counter += 1
    end
    if p.self in p.neighbors
        pos = findfirst(p.neighbors .== p.self)
        deleteat!(p.neighbors, pos)
    end
    @info "Process" p.self p.left p.right p.circ p.neighbors p.storage h(p.self) bitstring(id(p.self))

    MPI.Barrier(comm)
end

MPI.Init()

example_run()


MPI.Barrier(MPI.COMM_WORLD)


MPI.Finalize()