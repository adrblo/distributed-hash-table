function ∇(message, node, comm)
    MPI.Isend(message, comm; dest=node)
end

function ∘(handle_message, message)
    handle_message(message)
end

function build_handle_message(rank, comm, p)
    message_map = Dict(
            _info => (content) -> Message(cinfo; data=content),
            _linearize => (node) -> Message(clinearize; node=node),
        )

    map_from_message = Dict(
            noCommand => (f, n, d, s, p, ←) -> nothing,
            otherCommand => (f, n, d, s, p, ←) -> nothing,
            cinfo => (f, n, d, s, p, ←) -> _info(p, d),
            clinearize => (f, n, d, s, p, ←) -> _linearize(p, n, ←),
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

function _route(node::Int)
    """
    Returns the nearest node in routing strategy
    """
    return node+1
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