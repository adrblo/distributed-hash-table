function ∇(message, node, comm)
    MPI.Isend(message, comm; dest=node)
end

function ∘(handle_message, message)
    handle_message(message)
end

function build_handle_message(rank, comm, p)
    message_map = Dict(
            _info => (content) -> Message(command_info; data=content),
            _linearize => (node) -> Message(command_linearize; node=node),
            _trace => (node, from) -> Message(command_trace; node=node, from=from)
        )

    map_from_message = Dict(
            noCommand => (f, n, d, s, p, ←) -> nothing,
            otherCommand => (f, n, d, s, p, ←) -> nothing,
            command_info => (f, n, d, s, p, ←) -> _info(p, d),
            command_linearize => (f, n, d, s, p, ←) -> _linearize(p, n, ←),
            command_trace => (f, n, d, s, p, ←) -> _trace(p, n, ←, f)
        )

    function handle_message(message::Message)
        map_from_message[message.command](message.from, message.node, message.data, message.success, p, ←)
        @info string("Call_self: " * string(rank) * " ← " * string(message.command) * " from " * string(rank)) message
    end

    ←(node::Union{Int, Nothing}, op::Tuple) = begin
        if node === nothing
            return
        end

        message = message_map[op[1]](op[2]...)
        @info string("Call: " * string(node) * " ← " * string(op[1]) * " from " * string(rank)) node, message.command, op[2]
        if node == rank
            ∘(handle_message, message)
        else
            ∇(message, node, comm)
        end
    end

    return handle_message, ←
end

function _search(p, ←, from, data_hash::Float64)
    self_hash = h(p.self)
    left_hash = h(p.left)
    right_hash = h(p.right)
    if !(data_hash >= left_hash && data_hash <= right_hash)
        # greedy routing
    else
        if data_hash < self_hash
            p.left ← search(data_hash, from)
        end
        return
    end
end

function _trace(p::Process, node, ←, from)
    if node == p.self
        @info "Trace ARRIVED" from
        return
    else
        r = route(p.self, p.neighbors, node)
        @info "Trace" node from r
        r ← trace(node, from)
    end
end

function trace(node::Int, from::Int)
    (_trace, (node, from))
end


function _info(p::Process, content::Int)
    println(p.self, ": ", content)
end


function info(content::Int)
    return (_info, (content,))
end


function _search(x::Float16, from, success)

end


function searchX(x::Float16)
    return (_info, (x, from, success))
end

function _linearize(p::Process, node, ←)
    p.left ← linearize(0)
end

function linearize(node)
    return (_linearize, (node,))
end