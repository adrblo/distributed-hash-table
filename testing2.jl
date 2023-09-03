
struct Event
    start::Int
    ranks::Vector{Int}
    func::Function
end

function setup_events(rank, comm)
    # Events: (time in sec., ranks, function)
    events = [
        Event(10, [1, 2], () -> (3 ← () -> ())),
        Event(30, [1, 2], () -> (println("otherCommand", 2, comm))),
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
        if event.start <= time && !done
            event.func()
            done_events[index] = true
        else
            # may break, because events are sorted and assuming increasing time
            break
        end
    end
end

a, b = setup_events(1, 2)

check_and_do_events!(a, b, 10)

print(b)
